output "backups_bucket_id" {
  value = module.storage.backups_bucket_id
}

output "deploy_bucket_id" {
  value = module.storage.deploy_bucket_id
}

output "dns_forwarding_rules_arn" {
  value = aws_prdm_principal_association.fwd_inbound
}

output "ec2_keypair_name" {
  value = aws_key_pair.deployer.key_name
}

output "jenkins_server_fqdn" {
  value = module.jenkins.jenkins_server_fqdn
}

output "jenkins_sg_id" {
  value = module.jenkins.jenkins_sg_id
}

output "jenkins_worker_sg_id" {
  value = module.jenkins.jenkins_worker_sg_id
}

output "private_ca_arn" {
  value = aws_acmpca_certificate_authority.private_ca.arn
}

output "private_ca_issuing_arn" {
  value = aws_acmpca_certificate_authority.private_ca_issuing.arn
}

output "prometheus_server_fqdn" {
  value = module.prometheus.prometheus_server_fqdn
}

output "prometheus_sg_id" {
  value = module.prometheus.prometheus_sg_id
}

output "pypi_bucket_id" {
  value = module.storage.pypi_bucket_id
}

output "pypi_server_fqdn" {
  value = module.pypi.pypi_server_fqdn
}

output "pypi_sg_id" {
  value = module.pypi.pypi_sg_id
}

output "route_53_private_zone_id" {
  value = aws_route53_zone.private.zone_id
}

output "rundeck_server_fqdn" {
  value = module.rundeck.rundeck_server_fqdn
}

output "rundeck_sg_id" {
  value = module.rundeck.rundeck_sg_id
}
