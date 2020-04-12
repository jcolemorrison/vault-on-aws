# IAM Policies

## KMS Policy
data "aws_iam_policy_document" "kms_vault_policy" {
  statement {
    sid = "EncryptDecryptAndDescribe"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:DescribeKey"
    ]
    resources = [
      aws_kms_key.seal.arn
    ]
  }
}

## DynamoDB Policy
data "aws_iam_policy_document" "dynamodb_vault_policy" {
  statement {
    sid = "ManageTable"
    effect = "Allow"
    actions = [
      "dynamodb:BatchGetItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:PutItem",
      "dynamodb:DescribeTable",
      "dynamodb:DeleteItem",
      "dynamodb:GetItem",
      "dynamodb:ListTagsOfResource",
      "dynamodb:UpdateItem",
      "dynamodb:DescribeTimeToLive"
    ]
    resources = [
      aws_dynamodb_table.vault_storage.arn
    ]
  }

  statement {
    sid = "GetStreamRecords"
    effect = "Allow"
    actions = [
      "dynamodb:GetRecords"
    ]
    resources = [
      "${aws_dynamodb_table.vault_storage.arn}/stream/*"
    ]
  }

  statement {
    sid = "QueryAndScanTable"
    effect = "Allow"
    actions = [
      "dynamodb:Scan",
      "dynamodb:Query"
    ]
    resources = [
      "${aws_dynamodb_table.vault_storage.arn}/index/*",
      aws_dynamodb_table.vault_storage.arn
    ]
  }
}

## S3 Policy

data "aws_iam_policy_document" "s3_vault_policy" {
  statement {
    sid = "PutObjects"
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.vault_data.arn}/*"
    ]
  }
}

## AutoScalingGroup Instance Trust Policy
data "aws_iam_policy_document" "asg_trust_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = [
      "sts:AssumeRole"
    ]
  }
}
