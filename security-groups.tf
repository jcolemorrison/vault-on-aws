# Security Groups (SG)

## Load Balancer SG
resource "aws_security_group" "load_balancer" {
  name_prefix = "${var.main_project_tag}-alb-sg"
  description = "Firewall for the application load balancer fronting the vault instances."
  vpc_id = aws_vpc.vault.id
  tags = merge(
    { "Name" = "${var.main_project_tag}-alb-sg" },
    { "Project" = var.main_project_tag }
  )
}

resource "aws_security_group_rule" "load_balancer_allow_80" {
  security_group_id = aws_security_group.load_balancer.id
  type = "ingress"
  protocol = "tcp"
  from_port = 80
  to_port = 80
  cidr_blocks = var.allowed_traffic_cidr_blocks
  description = "Allow HTTP traffic."
}

resource "aws_security_group_rule" "load_balancer_allow_443" {
  security_group_id = aws_security_group.load_balancer.id
  type = "ingress"
  protocol = "tcp"
  from_port = 443
  to_port = 443
  cidr_blocks = var.allowed_traffic_cidr_blocks
  description = "Allow HTTPS traffic."
}

resource "aws_security_group_rule" "load_balancer_allow_outbound" {
  security_group_id = aws_security_group.load_balancer.id
  type = "egress"
  protocol    = "-1"
  from_port   = 0
  to_port     = 0
  cidr_blocks = ["0.0.0.0/0"]
  description = "Allow any outbound traffic."
}

## Vault Instance SG

resource "aws_security_group" "vault_instance" {
  name_prefix = "${var.main_project_tag}-vault-instance-sg"
  description = "Firewall for the vault instances."
  vpc_id = aws_vpc.vault.id
  tags = merge(
    { "Name" = "${var.main_project_tag}-vault-instance-sg" },
    { "Project" = var.main_project_tag }
  )
}

resource "aws_security_group_rule" "vault_instance_allow_8200" {
  security_group_id = aws_security_group.vault_instance.id
  type = "ingress"
  protocol = "tcp"
  from_port = 8200
  to_port = 8200
  source_security_group_id = aws_security_group.load_balancer.id
  description = "Allow traffic from Load Balancer."
}

resource "aws_security_group_rule" "vault_instance_allow_8201" {
  security_group_id = aws_security_group.vault_instance.id
  type = "ingress"
  protocol = "tcp"
  from_port = 8201
  to_port = 8201
  self = true
  description = "Allow traffic from fellow vault instances that have this SG."
}

resource "aws_security_group_rule" "vault_instance_allow_outbound" {
  security_group_id = aws_security_group.vault_instance.id
  type = "egress"
  protocol    = "-1"
  from_port   = 0
  to_port     = 0
  cidr_blocks = ["0.0.0.0/0"]
  description = "Allow any outbound traffic."
}

## Bastion SG

resource "aws_security_group" "bastion" {
  name_prefix = "${var.main_project_tag}-bastion-sg"
  description = "Firewall for the operator bastion instance"
  vpc_id = aws_vpc.vault.id
  tags = merge(
    { "Name" = "${var.main_project_tag}-bastion-sg" },
    { "Project" = var.main_project_tag }
  )
}

resource "aws_security_group_rule" "bastion_allow_22" {
  security_group_id = aws_security_group.bastion.id
  type = "ingress"
  protocol = "tcp"
  from_port = 22
  to_port = 22
  cidr_blocks = var.allowed_bastion_cidr_blocks
  description = "Allow SSH traffic."
}

resource "aws_security_group_rule" "bastion_allow_outbound" {
  security_group_id = aws_security_group.bastion.id
  type = "egress"
  protocol    = "-1"
  from_port   = 0
  to_port     = 0
  cidr_blocks = ["0.0.0.0/0"]
  description = "Allow any outbound traffic."
}