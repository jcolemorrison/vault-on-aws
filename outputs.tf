# Here for debugging the compiled userdata.sh file.
resource "local_file" "userdata_compiled" {
  content = templatefile("${path.root}/files/userdata_template.sh", {
    VAULT_VERSION = var.vault_version
    VAULT_CLUSTER_NAME = var.main_project_tag
    VAULT_DNS = var.domain_name
    VAULT_KMS_KEY_ID = aws_kms_key.seal.key_id
    VAULT_CLUSTER_REGION = data.aws_region.current.name
    VAULT_DYNAMODB_TABLE = var.dynamodb_table_name # dynamodb resource doesn't return name....
    VAULT_S3_BUCKET_NAME = aws_s3_bucket.vault_data.id
  })
  filename = "${path.root}/temp/userdata_compiled.sh"
}

# Output the vault credentials script
resource "local_file" "vault_credentials" {
  content = templatefile("${path.root}/files/vault_credentials_template.sh", {
    AWS_PROFILE = var.aws_profile
    AWS_REGION = data.aws_region.current.name
    AWS_S3_BUCKET = aws_s3_bucket.vault_data.id
    AWS_KMS_KEY_ID = aws_kms_key.seal.key_id
    LOAD_BALANCER_DNS_NAME = aws_lb.alb.dns_name
  })
  filename = "${path.root}/temp/vault_credentials.sh"
}

# Load Balancer DNS - You need to CNAME or Alias this.
output "load_balancer_dns" {
  value = aws_lb.alb.dns_name
}

# VPC Values

output "vpc_id" {
  value = aws_vpc.vault.id
}

output "vpc_ipv4_cidr" {
  value = aws_vpc.vault.cidr_block
}

output "vpc_ipv6_cidr" {
  value = aws_vpc.vault.ipv6_cidr_block
}