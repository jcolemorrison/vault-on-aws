# IAM Roles

## Role for Vault EC2 Instances via AutoScalingGroup

resource "aws_iam_role" "vault_instance" {
  name_prefix = "${var.main_project_tag}-instance-role-"
  assume_role_policy = data.aws_iam_policy_document.asg_trust_policy.json
}

## Policy Attachments

resource "aws_iam_role_policy" "vault_instance_kms_policy" {
  name_prefix = "${var.main_project_tag}-instance-kms-policy-"
  role = aws_iam_role.vault_instance.id
  policy = data.aws_iam_policy_document.kms_vault_policy.json
}

resource "aws_iam_role_policy" "vault_instance_dynamodb_policy" {
  name_prefix = "${var.main_project_tag}-instance-dynamodb-policy-"
  role = aws_iam_role.vault_instance.id
  policy = data.aws_iam_policy_document.dynamodb_vault_policy.json
}

resource "aws_iam_role_policy" "vault_instance_s3_policy" {
  name_prefix = "${var.main_project_tag}-instance-s3-policy-"
  role = aws_iam_role.vault_instance.id
  policy = data.aws_iam_policy_document.s3_vault_policy.json
}

## Instance Profile

resource "aws_iam_instance_profile" "vault_instance_profile" {
  name_prefix = "${var.main_project_tag}-instance-profile-"
  role = aws_iam_role.vault_instance.name
}