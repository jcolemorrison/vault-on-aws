#!/bin/bash

# This grabs the encrypted credentials file and decrypts it.

aws --profile ${AWS_PROFILE} --region ${AWS_REGION} s3 cp s3://${AWS_S3_BUCKET}/vault_creds_encrypted ./tmp/vault_creds_encrypted
aws --profile ${AWS_PROFILE} --region ${AWS_REGION} kms decrypt --key-id ${AWS_KMS_KEY_ID} --ciphertext-blob fileb://tmp/vault_creds_encrypted --output text --query Plaintext | base64 --decode > ./tmp/vault_creds_decrypted
