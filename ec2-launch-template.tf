# EC2 Launch Template
resource "aws_launch_template" "vault_instance" {
  name_prefix = "${var.main_project_tag}-lt-"
  image_id = var.use_lastest_ami ? data.aws_ssm_parameter.latest_ami.value : "ami-0323c3dd2da7fb37d"
  instance_type = var.vault_instance_type
  key_name = var.ec2_key_pair_name
  vpc_security_group_ids = [aws_security_group.vault_instance.id]

  iam_instance_profile {
    arn = aws_iam_instance_profile.vault_instance_profile.arn
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      { "Name" = "${var.main_project_tag}-instance" },
      { "Project" = var.main_project_tag }
    )
  }

  tag_specifications {
    resource_type = "volume"
    
    tags = merge(
      { "Name" = "${var.main_project_tag}-volume" },
      { "Project" = var.main_project_tag }
    )
  }

  tags = merge(
    { "Name" = "${var.main_project_tag}-lt" },
    { "Project" = var.main_project_tag }
  )

  user_data = base64encode(templatefile("${path.module}/files/userdata_template.sh", {
    VAULT_VERSION = var.vault_version
    VAULT_CLUSTER_NAME = var.main_project_tag
    VAULT_DNS = var.domain_name
    VAULT_KMS_KEY_ID = aws_kms_key.seal.key_id
    VAULT_CLUSTER_REGION = data.aws_region.current.name
    VAULT_DYNAMODB_TABLE = var.dynamodb_table_name # dynamodb resource doesn't return name....
    VAULT_S3_BUCKET_NAME = aws_s3_bucket.vault_data.id
  }))
}