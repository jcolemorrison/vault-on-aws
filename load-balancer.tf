# Load Balancer
# 
# HTTPS is terminated at the load balancer.  The load balancer will then communicate
# with the targets over HTTP.  The Targets (vault instances) are in a private
# subnet, cut off from any external access.  This means that they're still perfectly
# secure AND we don't incur the overhead of extra TLS handshakes and encryption.

## Application Load Balancer
resource "aws_lb" "alb" {
  // Can't give it a full name_prefix due to 32 character limit on LBs
  // and the fact that Terraform adds a 26 character random bit to the end.
  // https://github.com/terraform-providers/terraform-provider-aws/issues/1666
  name_prefix = "vault-"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.load_balancer.id]
  subnets = aws_subnet.public.*.id
  idle_timeout = 60
  ip_address_type = "dualstack"

  tags = merge(
    { "Name" = "${var.main_project_tag}-alb"},
    { "Project" = var.main_project_tag }
  )
}

## Target Group
resource "aws_lb_target_group" "alb_targets" {
  name_prefix = "vault-"
  port = 8200
  protocol = "HTTP"
  vpc_id = aws_vpc.vault.id
  deregistration_delay = 30
  target_type = "instance"

  health_check {
    enabled = true
    interval = 10
    path = "/v1/sys/health" // the Vault API health port
    protocol = "HTTP"
    timeout = 5
    healthy_threshold = 3
    unhealthy_threshold = 3
    matcher = "200"
  }

  tags = merge(
    { "Name" = "${var.main_project_tag}-tg"},
    { "Project" = var.main_project_tag }
  )
}

## Load Balancer Listeners
##
## Note: There is NO HTTP listener.  Yes, the convention is to set one up and
## then force a redirect to HTTPS.  However, this presents a scenario where
## some genius sends up a requet with their token or credentials over HTTP
## and is then redirected to HTTPS.  During that redirect, the credentials
## would be exposed.

resource "aws_lb_listener" "alb_https" {
  load_balancer_arn = aws_lb.alb.arn
  port = 443
  protocol = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-FS-2018-06" // Enable Forward Secrecy
  certificate_arn = data.aws_acm_certificate.vault_alb_cert.arn

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.alb_targets.arn
  }
}