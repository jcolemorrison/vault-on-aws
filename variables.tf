# REQUIRED VARIABLES

# SSL Certificate for HTTPS Access

variable "domain_name" {
  description = "Domain name for which you've provisioned an SSL certificate via AWS Certificate Manager.  Example: secrets.examples.com.  Do not include the protocol (i.e. https://)."
  type = string
}

# EC2 - General

variable "ec2_key_pair_name" {
  description = "Name of an existing EC2 Key Pair that exists in the same region as your vault deployment.  Needs to be made separately."
  type = string
}

# OPTIONAL VARIABLES

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
  description = "The default AWS region to deploy the Vault infrastructure to."
  type = string
  default = "us-east-1"
}

# Vault Version

variable "vault_version" {
  description = "Version of vault to use."
  type = string
  default = "1.4.0"
}

# Operator Mode
## Turning this on will enable NAT and Bastion to access the Vault Instances

variable "operator_mode" {
  description = "Enable a NAT Gateway and Bastion for operator access into the Vault Instances."
  type = bool
  default = true
}

# Private Deploy
## Turning this on will make it so that the Vault Deployemnt is only available through VPC peering

variable "private_mode" {
  description = "Whether or not the Vault deployment should be private."
  type = bool
  default = false
}

## A VPC in the SAME AWS Account and REGION as your Vault deployment.  The VPCs MUST have "enable dns hostnames" active AND cannot use the same CIDR block as the Vault VPC.
variable "peered_vpc_ids" {
  description = "A list of of a VPC IDs that can access the Vault VPC and thus access vault privately."
  type = list(string)
  default = []
}

# Allowed Traffic
## What IP Address ranges (via CIDR) are allowed to access your vault?

variable "allowed_traffic_cidr_blocks" {
  description = "List of CIDR blocks allowed to send requests to your vault endpoint.  Defaults to EVERYWHERE.  You should probably limit this to your organization IP or VPC CIDR."
  type = list(string)
  default = ["0.0.0.0/0"]
}

variable "allowed_traffic_cidr_blocks_ipv6" {
  description = "List of IPv6 CIDR blocks allowed to send requests to your vault endpoint.  Defaults to EVERYWHERE.  Set to an empty list if not required."
  type = list(string)
  default = ["::/0"]
}

## What IP Address range can access your bastion server?
variable "allowed_bastion_cidr_blocks" {
  description = "List of CIDR blocks allowed to access your Bastion.  Defaults to EVERYWHERE.  You should probably limit this to your organization IP or VPC CIDR."
  type = list(string)
  default = ["0.0.0.0/0"]
}

variable "allowed_bastion_cidr_blocks_ipv6" {
  description = "List of CIDR blocks allowed to access your Bastion.  Defaults to none."
  type = list(string)
  default = []
}

# AWS VPC

variable "vpc_cidr" {
  description = "Cidr block for the VPC.  Using a /16 or /20 Subnet Mask is recommended."
  type = string
  default = "10.255.0.0/20"
}

variable "vpc_instance_tenancy" {
  description = "Tenancy for instances launched into the VPC."
  type = string
  default = "default"
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

# EC2 - Vault Instance Launch Template

variable "vault_instance_type" {
  description = "The EC2 instance size of the vault instances."
  type = string
  default = "t2.medium"
}

# EC2 - Vault Instance AutoScaling Group

variable "vault_instance_count" {
  description = "The number of EC2 instances to launch as vault instances.  Should be no less than 2."
  type = number
  default = 2
}


# EC2 - AMI

variable "use_lastest_ami" {
  description = "Whether or not to use the latest version of Amazon Linux 2.  Defaults to false and uses a version that is known to work with this deployment."
  type = bool
  default = false
}

# DynamoDB

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB Table used for the Vault Storage Backend."
  type = string
  default = "vault_storage"
}

# KMS

variable "kms_tags" {
  description = "Tags for the KMS key used to seal and unseal the Vault."
  type = map(string)
  default = {}
}
