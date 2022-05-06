output "terraform_admin_role_arn" {
  value = aws_iam_role.terraform_admin_role.arn
}

output "terraform_admin_user_arn" {
  value = aws_iam_user.terraform_admin_user.arn
}

output "terraform_implicit_role_arn" {
  value = aws_iam_role.terraform_implicit_role.arn
}

output "terraform_state_bucket_id" {
  value = aws_s3_bucket.terraform_state.id
}

output "terraform_state_dynamodb_table_id" {
  value = aws_dynamodb_table.terraform_state_lock.id
}
