
####################################################
# variable
####################################################
variable "domain" {
  description = "domain name"
  type        = string
  default     = "command-style.com"
}

####################################################
# Route53 zone
####################################################
data "aws_route53_zone" "main" {
  name = var.domain
  private_zone = false
}

####################################################
# ACM
####################################################
resource "aws_acm_certificate" "main" {
    domain_name       = var.domain
    validation_method = "DNS"
    lifecycle {
      create_before_destroy = true
    }
}

resource "aws_route53_record" "validation" {
    depends_on = [aws_acm_certificate.main]
    for_each = {
      for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
        name   = dvo.resource_record_name
        record = dvo.resource_record_value
        type   = dvo.resource_record_type
      }
    }
    type       = each.value.type
    name       = each.value.name
    records    = [each.value.record]
    ttl        = 60
    zone_id    = data.aws_route53_zone.main.id
}

resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}