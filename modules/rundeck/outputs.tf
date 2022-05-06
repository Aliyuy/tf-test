output "rundeck_certificate_arn" {
  value = aws_acm_certificate.rundeck.arn
}

output "rundeck_server_fqdn" {
  value = aws_route53_record.rundeck.fqdn
}

output "rundeck_sg_id" {
  value = aws_security_group.rundeck.id
}
