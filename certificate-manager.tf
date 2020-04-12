# Certificate Manager
# This requires you to have already provisioned and validated a certificate via AWS Certificate Manager

data "aws_acm_certificate" "vault_alb_cert" {
  domain = var.domain_name
}
