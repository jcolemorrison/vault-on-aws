# VPC
resource "aws_vpc" "vault" {
  cidr_block = var.vpc_cidr
  instance_tenancy = var.vpc_instance_tenancy
  enable_dns_support = true
  enable_dns_hostnames = true # required for VPC peering.
  assign_generated_ipv6_cidr_block = true

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

## Egress Only Gateway (IPv6)
resource "aws_egress_only_internet_gateway" "eigw" {
  vpc_id = aws_vpc.vault.id
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

  allocation_id = aws_eip.nat[0].id // same as aws_eip.nat.0.id
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
// NOTE: Routing to the VPC's CIDR is allowed by default, so no route is needed

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

resource "aws_route" "private_internet_access_ipv6" {
  count = var.operator_mode ? 1 : 0

  route_table_id = aws_route_table.private.id
  destination_ipv6_cidr_block = "::/0"
  egress_only_gateway_id = aws_egress_only_internet_gateway.eigw.id
}










# Subnets

## Public Subnets
resource "aws_subnet" "public" {
  count = var.vpc_public_subnet_count

  vpc_id = aws_vpc.vault.id
  cidr_block = cidrsubnet(aws_vpc.vault.cidr_block, 4, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  ipv6_cidr_block = cidrsubnet(aws_vpc.vault.ipv6_cidr_block, 8, count.index)
  assign_ipv6_address_on_creation = true

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

  // Increment the netnum by the number of public subnets to avoid overlap
  cidr_block = cidrsubnet(aws_vpc.vault.cidr_block, 4, count.index + var.vpc_public_subnet_count)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(
    { "Name" = "${var.main_project_tag}-private-${data.aws_availability_zones.available.names[count.index]}"},
    { "Project" = var.main_project_tag },
    var.vpc_tags
  )
}









# Route Table Associations

## Public Subnet Route Associations
resource "aws_route_table_association" "public" {
  count = var.vpc_public_subnet_count

  subnet_id = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

## Private Subnet Route Associations
resource "aws_route_table_association" "private" {
  count = var.vpc_private_subnet_count

  subnet_id = element(aws_subnet.private.*.id, count.index)
  route_table_id = aws_route_table.private.id
}







# VPC Endpoints
// Make safe calls to KMS and DynamoDB without leaving the VPC.  Because #awsthings.  C'mon.  This should be default without these things.

## KMS Endpoint
data "aws_vpc_endpoint_service" "kms" {
  service = "kms"
}

#### To get the required data, if you're confused, just output the above KMS data source.  It has all the details.
resource "aws_vpc_endpoint" "kms" {
  service_name = data.aws_vpc_endpoint_service.kms.service_name
  vpc_id = aws_vpc.vault.id
  private_dns_enabled = true

  // Can also be done with "aws_vpc_endpoint_subnet_association"
  subnet_ids = aws_subnet.private.*.id
  security_group_ids = [aws_security_group.kms_endpoint.id]

  tags = merge(
    { "Name" = "${var.main_project_tag}-kms-endpoint"},
    { "Project" = var.main_project_tag },
    var.vpc_tags
  )

  vpc_endpoint_type = "Interface" // KMS is indeed an interface type
}

## DynamoDB Endpoint
data "aws_vpc_endpoint_service" "dynamodb" {
  service = "dynamodb"
}

resource "aws_vpc_endpoint" "dynamodb" {
  service_name = data.aws_vpc_endpoint_service.dynamodb.service_name
  vpc_id = aws_vpc.vault.id

  // Can also be done with "aws_vpc_endpoint_route_table_association"
  route_table_ids = [aws_route_table.private.id]
  
  tags = merge(
    { "Name" = "${var.main_project_tag}-dynamodb-endpoint"},
    { "Project" = var.main_project_tag },
    var.vpc_tags
  )

  vpc_endpoint_type = "Gateway"
}






# VPC Peering
## Enabled in Private Mode only.  Allows other VPCs in the same account and region to access your Vault VPC.

## Data from Peered VPC (AKA the external VPC we're letting in)
data "aws_vpc" "peered_vpc" {
  count = var.private_mode && length(var.peered_vpc_ids) > 0 ? length(var.peered_vpc_ids) : 0

  id = var.peered_vpc_ids[count.index]
}

## Peering Connections
resource "aws_vpc_peering_connection" "vault" {
  count = var.private_mode && length(var.peered_vpc_ids) > 0 ? length(var.peered_vpc_ids) : 0

  peer_vpc_id = var.peered_vpc_ids[count.index]
  vpc_id = aws_vpc.vault.id
  auto_accept = true

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }

  tags = merge(
    { "Name" = "${var.main_project_tag}-vpc-peering-connection-${count.index + 1}"},
    { "Project" = var.main_project_tag },
    var.vpc_tags
  )
}

## Peering Connection Routes for the VAULT Route Table
resource "aws_route" "requester_peering_route" {
  count = var.private_mode && length(var.peered_vpc_ids) > 0 ? length(var.peered_vpc_ids) : 0

  route_table_id = aws_route_table.public.id
  destination_cidr_block = data.aws_vpc.peered_vpc[count.index].cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.vault[count.index].id
}

## Peering Connection Routes for the External VPC Route Tables to allow Vault Traffic
## Note: this associates it to the external VPC's MAIN ROUTE TABLE.
## If you want it associated to a different route table, you'll have to do so manually or set the table you want as the main route table.
resource "aws_route" "accepter_peering_route" {
  count = var.private_mode && length(var.peered_vpc_ids) > 0 ? length(var.peered_vpc_ids) : 0

  route_table_id = data.aws_vpc.peered_vpc[count.index].main_route_table_id
  destination_cidr_block = aws_vpc.vault.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.vault[count.index].id
}