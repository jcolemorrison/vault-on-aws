# AWS KMS Key
resource "aws_kms_key" "seal" {
  description = "The KMS key to unseal Vault."
  enable_key_rotation = true

  tags = merge(
    { "Name" = "${var.main_project_tag}-seal-key" },
    { "Project" = var.main_project_tag },
    var.kms_tags
  )
}

resource "aws_kms_alias" "seal" {
  name = "alias/${var.main_project_tag}-seal-key"
  target_key_id = aws_kms_key.seal.key_id
}