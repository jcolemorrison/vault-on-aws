# DynamoDB

resource "aws_dynamodb_table" "vault_storage" {
  name = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "Path"
  range_key = "Key"

  attribute {
    name = "Path"
    type = "S"
  }

  attribute {
    name = "Key"
    type = "S"
  }

  tags = {
    Name = var.dynamodb_table_name
    Project = var.main_project_tag
  }
}