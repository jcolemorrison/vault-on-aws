# VPC
resource "aws_vpc" "vault" {
  cidr_block = var.vpc_cidr
  instance_tenancy = var.vpc_instance_tenancy
  enable_dns_support = var.vpc_enable_dns_support
  enable_dns_hostnames = var.vpc_enable_dns_hostnames

  tags = merge(
    { "Name" = "${var.main_project_tag}-vpc" },
    { "Project" = var.main_project_tag },
    var.vpc_tags
  )
}










# Gateways

## Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vault.id

  tags = merge(
    { "Name" = "${var.main_project_tag}-igw"},
    { "Project" = var.main_project_tag },
    var.vpc_tags
  )
}

## NAT Gateway

#### The NAT Elastic IP
resource "aws_eip" "nat" {
  count = var.operator_mode ? 1 : 0

  vpc = true

  tags = merge(
    { "Name" = "${var.main_project_tag}-nat-eip"},
    { "Project" = var.main_project_tag },
    var.vpc_tags
  )

  depends_on = [aws_internet_gateway.igw]
}

#### The NAT Gateway
resource "aws_nat_gateway" "nat" {
  count = var.operator_mode ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id = aws_subnet.public.0.id

  tags = merge(
    { "Name" = "${var.main_project_tag}-nat"},
    { "Project" = var.main_project_tag },
    var.vpc_tags
  )

  depends_on = [
    aws_internet_gateway.igw,
    aws_eip.nat
  ]
}










# Route Tables
# NOTE: Routing to the VPC's CIDR is allowed by default, so no route is needed

## Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vault.id
  tags = merge(
    { "Name" = "${var.main_project_tag}-public-rtb"},
    { "Project" = var.main_project_tag },
    var.vpc_tags
  )
}

#### Public routes
resource "aws_route" "public_internet_access" {
  route_table_id = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}

## Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vault.id
  tags = merge(
    { "Name" = "${var.main_project_tag}-private-rtb"},
    { "Project" = var.main_project_tag },
    var.vpc_tags
  )
}

#### Private Routes
resource "aws_route" "private_internet_access" {
  count = var.operator_mode ? 1 : 0

  route_table_id = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat[0].id
}










# Subnets

## Public Subnets
resource "aws_subnet" "public" {
  count = var.vpc_public_subnet_count

  vpc_id = aws_vpc.vault.id
  cidr_block = cidrsubnet(aws_vpc.vault.cidr_block, 4, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    { "Name" = "${var.main_project_tag}-public-${data.aws_availability_zones.available.names[count.index]}"},
    { "Project" = var.main_project_tag },
    var.vpc_tags
  )
}

## Private Subnets
resource "aws_subnet" "private" {
  count = var.vpc_private_subnet_count

  vpc_id = aws_vpc.vault.id

  # Increment the netnum by the number of public subnets to avoid overlap
  cidr_block = cidrsubnet(aws_vpc.vault.cidr_block, 4, count.index + var.vpc_public_subnet_count)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(
    { "Name" = "${var.main_project_tag}-private-${data.aws_availability_zones.available.names[count.index]}"},
    { "Project" = var.main_project_tag },
    var.vpc_tags
  )
}









# VPC Endpoints
# Make safe calls to KMS and DynamoDB without leaving the VPC.
