output "sensu_certificate_arn" {
  value = aws_acm_certificate.sensu.arn
}

output "sensu_server_fqdn" {
  value = aws_route53_record.sensu.fqdn
}

output "sensu_sg_id" {
  value = aws_security_group.sensu.id
}
