# Organization

variable "main_project_tag" {
  description = "Tag that will be attached to all resources."
  type = string
  default = "vault-deployment"
}

# AWS Provider

variable "aws_profile" {
  description = "The AWS Profile to use for this project."
  type = string
  default = "default"
}

variable "aws_default_region" {
  description = "The default region to deploy this."
  type = string
  default = "us-east-1"
}

# AWS VPC

variable "vpc_cidr" {
  description = "Cidr block for the VPC.  Using a /16 or /20 Subnet Mask is recommended."
  type = string
  default = "10.255.0.0/20"
}

variable "vpc_instance_tenancy" {
  description = "Tenancy for instances launched into the VPC"
  type = string
  default = "default"
}

variable "vpc_enable_dns_support" {
  description = "Whether the DNS resolution is supported."
  type = bool
  default = true
}

variable "vpc_enable_dns_hostnames" {
  description = "Whether instances with public IP addresses get corresponding public DNS hostnames."
  type = bool
  default = true
}

variable "vpc_tags" {
  description = "Additional tags to add to the VPC and its resources."
  type = map(string)
  default = {}
}

# VPC Subnets

variable "vpc_public_subnet_count" {
  description = "The number of public subnets to create.  Cannot exceed the number of AZs in your selected region.  2 is more than enough."
  type = number
  default = 2
}

variable "vpc_private_subnet_count" {
  description = "The number of private subnets to create.  Cannot exceed the number of AZs in your selected region."
  type = number
  default = 2
}

# KMS

variable "kms_tags" {
  description = "Tags for the KMS key used to seal and unseal the Vault."
  type = map(string)
  default = {}
}

# DynamoDB

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB Table used for the Vault Storage Backend."
  type = string
  default = "vault_storage"
}

# Operator Mode
## Turning this on will enable NAT and Bastion to access the Vault Instances

variable "operator_mode" {
  description = "Enable a NAT Gateway and Bastion for operator access into the Vault Instances."
  type = bool
  default = true
}