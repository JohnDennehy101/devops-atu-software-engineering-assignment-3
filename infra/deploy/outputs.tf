###################################################################################################
# Output Fully Qualified Domain Name of deployed infra - (so easy to copy and paste into browser) #
###################################################################################################

output "static_site_address" {
  value = aws_route53_record.static_site.fqdn
}
