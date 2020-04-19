Content-Type: multipart/mixed; boundary="==BOUNDARY=="
MIME-Version: 1.0

--==BOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash

# Run Order: 1
# Run Frequency: only once, on first boot

# Tasks:
# - Install Dependencies
# - Make users and directories
# - Install download, unzip, and setup vault bin

# Note: dollar-sign curly braces are template values from Terraform.
# Non curly brace ones are normal bash variables...

yum update -y
yum install -y jq

# Make the user
useradd --system --shell /sbin/nologin vault

# Make the directories
mkdir -p "/opt/vault"
mkdir -p "/opt/vault/bin"
mkdir -p "/opt/vault/config"

# Give corret permissions
chmod 755 "/opt/vault"
chmod 755 "/opt/vault/bin"

# Change ownership to vault user
chown -R "vault:vault" "/opt/vault"

# Download the vault bin
curl -o /tmp/vault.zip https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip

# unzip it in the /tmp dir
unzip -d /tmp /tmp/vault.zip

# move it to the /opt/vault/bin dir
mv /tmp/vault /opt/vault/bin

# give ownership to the vault user
chown vault:vault /opt/vault/bin

# create a symlink
ln -s /opt/vault/bin/vault /usr/local/bin/vault

# allow vault permissions to use mlock and prevent memory from swapping to disk
setcap cap_ipc_lock=+ep /opt/vault/bin/vault

--==BOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash

# Run Order: 2
# Run Frequency: only once, on first boot

# Tasks:
# - Make the vault config file
# - Make the systemd service file

# The vault config file
cat > /opt/vault/config/server.hcl <<- EOF
cluster_name = "${VAULT_CLUSTER_NAME}"
max_lease_ttl = "192h"
default_lease_ttl = "192h"
ui  = "true"

# Where can the Vault API be reached?  At DNS for the load balancer, or the CNAME created.
# Note: this maps to the environment variable VAULT_API_ADDR not VAULT_ADDR
api_addr = "https://${VAULT_DNS}"

# For forwarding between vault servers.  Set to own ip.
cluster_addr = "http://INSTANCE_IP_ADDR:8201"

# Auto unseal the vault
seal "awskms" {
  region = "${VAULT_CLUSTER_REGION}"
  kms_key_id = "${VAULT_KMS_KEY_ID}"
}

# Listener for loopback
listener "tcp" {
  address = "127.0.0.1:8200"
  tls_disable = "true"
}

# Listener for private network
listener "tcp" {
  address = "INSTANCE_IP_ADDR:8200"
  cluster_address = "INSTANCE_IP_ADDR:8201"

  # off, because they all talk in a private subnet
  tls_disable = "true"
}

storage "dynamodb" {
  ha_enabled = "true"
  region = "${VAULT_CLUSTER_REGION}"
  table = "${VAULT_DYNAMODB_TABLE}"
}
EOF

chwon vault:vault /opt/vault/config/server.hcl

# The systemd service file
cat > /etc/systemd/system/vault.service <<- EOF
[Unit]
Description=Vault Server on AWS
Requires=network-online.target
After=network-online.target

[Service]
User=vault
Group=vault
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=yes
PrivateDevices=yes
SecureBits=keep-caps
AmbientCapabilities=CAP_IPC_LOCK
Capabilities=CAP_IPC_LOCK+ep
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=/opt/vault/bin/vault server -config=/opt/vault/config/ -log-level=info
ExecReload=/bin/kill --signal HUP \$MAINPID
KillMode=process
KillSignal=SIGINT
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
StartLimitInterval=60
StartLimitBurst=3
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

--==BOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash

# Run Order: 3
# Run Frequency: only once, on first boot

# Tasks:
# - Replace values in configuration files with instance metadata
# - Start vault

INSTANCE_IP_ADDR=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
sed -i -e "s/INSTANCE_IP_ADDR/$INSTANCE_IP_ADDR/g" /opt/vault/config/server.hcl

systemctl daemon-reload
systemctl enable vault
systemctl restart vault

--==BOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash

# Run Order: 4
# Run Frequency: only once, on first boot

# Tasks:
# - Initialize Vault
# - Create credentials file
# - Encrypt the file via KMS
# - Send the file to S3
# - Delete the local file
# - Erase bash history

# Workaround to make sure the vault service is fully initialized.
sleep 10

export VAULT_ADDR="http://127.0.0.1:8200"
export AWS_DEFAULT_REGION="${VAULT_CLUSTER_REGION}"

VAULT_INITIALIZED=$(vault operator init -status)

function initialize_vault {
  # initialize and pipe to file
  vault operator init > vault_credentials.txt

  # encrypt it with the KMS key
  aws kms encrypt --key-id ${VAULT_KMS_KEY_ID} --plaintext fileb://vault_credentials.txt --output text --query CiphertextBlob | base64 --decode > vault_creds_encrypted

  # send the encrypted file to the s3 bucket
  aws s3 cp vault_creds_encrypted s3://${VAULT_S3_BUCKET_NAME}/

  # cleanup
  rm vault_credentials.txt
  history -c
  history -w
}

if [ "$VAULT_INITIALIZED" = "Vault is initialized" ]; then
  echo "Vault is already initialized."
else
  echo "Initializing vault..."
  initialize_vault
fi

--==BOUNDARY==--