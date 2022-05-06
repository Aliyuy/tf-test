output "pypi_server_fqdn" {
  value = aws_route53_record.pypi.fqdn
}

output "pypi_sg_id" {
  value = aws_security_group.pypi.id
}
