output "backups_bucket_id" {
  value = aws_s3_bucket.backups.id
}

output "deploy_bucket_id" {
  value = aws_s3_bucket.deploy.id
}

output "pypi_bucket_id" {
  value = aws_s3_bucket.pypi.id
}
