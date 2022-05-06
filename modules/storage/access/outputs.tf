output "fullaccess_policy_arn" {
  value = aws_iam_policy.bucket-fullaccess.arn
}

output "writeaccess_policy_arn" {
  value = aws_iam_policy.bucket-writeaccess.arn
}

output "readonly_policy_arn" {
  value = aws_iam_policy.bucket-readonly.arn
}
