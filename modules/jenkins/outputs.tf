output "jenkins_certificate_arn" {
  value = aws_acm_certificate.jenkins.arn
}

output "jenkins_server_fqdn" {
  value = aws_route53_record.jenkins.fqdn
}

output "jenkins_sg_id" {
  value = aws_security_group.jenkins.id
}

output "jenkins_worker_sg_id" {
  value = aws_security_group.jenkins_worker.id
}
