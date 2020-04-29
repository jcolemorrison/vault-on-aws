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
  internal = var.private_mode
  load_balancer_type = "application"
  security_groups = [aws_security_group.load_balancer.id]
  subnets = aws_subnet.public.*.id
  idle_timeout = 60
  ip_address_type = var.private_mode ? "ipv4" : "dualstack"

  tags = merge(
    { "Name" = "${var.main_project_tag}-alb"},
    { "Project" = var.main_project_tag }
  )
}

## Target Group
resource "aws_lb_target_group" "alb_targets" {
  name_prefix = "vault-"
  port = 8200
  protocol = "HTTPS"
  vpc_id = aws_vpc.vault.id
  deregistration_delay = 30
  target_type = "instance"

  health_check {
    enabled = true
    interval = 10
    path = "/v1/sys/health" // the Vault API health port
    protocol = "HTTPS"
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

### Redirect to HTTPS
resource "aws_lb_listener" "alb_http_redirect" {
  load_balancer_arn = aws_lb.alb.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "redirect"

    // For information on the below reserved keywords
    // https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#rule-action-types
    redirect {
      host = "#{host}"
      path = "/#{path}"
      port = 443
      protocol = "HTTPS"
      query = "#{query}"
      status_code = "HTTP_301"
    }
  }
}

### HTTPS
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