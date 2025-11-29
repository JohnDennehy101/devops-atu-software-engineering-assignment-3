###################################################
# Retrieve current route 53 zone linked to domain #
###################################################

data "aws_route53_zone" "site_zone" {
  name = "${var.dns_zone_name}."
}

#########################################################
# Obtain Route 53 CNAME record depending on environment #
#########################################################

resource "aws_route53_record" "site" {
  zone_id = data.aws_route53_zone.site_zone.zone_id
  name    = "${lookup(var.subdomain, terraform.workspace)}.${data.aws_route53_zone.site_zone.name}"
  type    = "CNAME"
  ttl     = "300"

  records = [aws_lb.primary.dns_name]
}

#########################################
# Route 53 record for Grafana subdomain #
#########################################

resource "aws_route53_record" "grafana" {
  zone_id = data.aws_route53_zone.site_zone.zone_id
  name    = "grafana.${lookup(var.subdomain, terraform.workspace)}.${data.aws_route53_zone.site_zone.name}"
  type    = "CNAME"
  ttl     = "300"

  records = [aws_lb.primary.dns_name]
}

################################################
# Define ACM certificate for Grafana subdomain #
################################################

resource "aws_acm_certificate" "grafana_cert" {
  domain_name       = aws_route53_record.grafana.name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

#####################################
# Define ACM certificate for domain #
#####################################

resource "aws_acm_certificate" "cert" {
  domain_name       = aws_route53_record.site.name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

}

#######################################
# Validate ACM certificate for domain #
#######################################

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for individual_domain_validation_option in aws_acm_certificate.cert.domain_validation_options :
    individual_domain_validation_option.domain_name => individual_domain_validation_option
  }

  allow_overwrite = true
  name            = each.value.resource_record_name
  type            = each.value.resource_record_type
  records         = [each.value.resource_record_value]
  ttl             = 60
  zone_id         = data.aws_route53_zone.site_zone.zone_id
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

###################################################
# Validate ACM certificate for Grafana sub domain #
###################################################

resource "aws_route53_record" "grafana_cert_validation" {
  for_each = {
    for individual_domain_validation_option in aws_acm_certificate.grafana_cert.domain_validation_options :
    individual_domain_validation_option.domain_name => individual_domain_validation_option
  }

  allow_overwrite = true
  name            = each.value.resource_record_name
  type            = each.value.resource_record_type
  records         = [each.value.resource_record_value]
  ttl             = 60
  zone_id         = data.aws_route53_zone.site_zone.zone_id
}

resource "aws_acm_certificate_validation" "grafana_cert" {
  certificate_arn         = aws_acm_certificate.grafana_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.grafana_cert_validation : record.fqdn]
}
