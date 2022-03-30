# S3

## S3 Bucket for Vault Data
resource "aws_s3_bucket" "vault_data" {
  bucket_prefix = "${var.main_project_tag}-"

  tags = merge({ "Project" = var.main_project_tag })
}

## S3 Server-side bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "vault_data_sse" {
  bucket = aws_s3_bucket.vault_data.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}

## S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "vault_data" {
  bucket = aws_s3_bucket.vault_data.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}
