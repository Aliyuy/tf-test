terraform {
  backend "s3" {
    bucket         = "ex-adm-adm-ue1-terraform-state"
    region         = "us-east-1"
    encrypt        = false
    dynamodb_table = "ex-adm-adm-ue1-terraform-lock"
    role_arn       = "arn:aws:iam::975163932648:role/TerraformAssumedIamRole"
  }
}
