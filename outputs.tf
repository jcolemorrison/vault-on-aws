# Here for debugging the compiled userdata.sh file.
resource "local_file" "user_data_compiled" {
  content = templatefile("${path.module}/files/userdata.sh", {
    VAULT_VERSION = var.vault_version
    VAULT_CLUSTER_NAME = var.main_project_tag
    VAULT_LOAD_BALANCER_DNS = aws_lb.alb.dns_name
    VAULT_KMS_KEY_ID = aws_kms_key.seal.key_id
    VAULT_CLUSTER_REGION = data.aws_region.current.name
    VAULT_DYNAMODB_TABLE = var.dynamodb_table_name # dynamodb resource doesn't return name....
    VAULT_S3_BUCKET_NAME = aws_s3_bucket.vault_data.id
  })
  filename = "${path.module}/files/user_data_compiled.sh"
}