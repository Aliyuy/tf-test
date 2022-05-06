output "prometheus_server_fqdn" {
  value = aws_route53_record.prometheus.fqdn
}

output "prometheus_sg_id" {
  value = aws_security_group.prometheus.id
}
