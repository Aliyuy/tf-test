variable "account_code" {
  description = "The short code for the AWS account this environment uses."
}

variable "aws_account_number" {
  description = "The account number of the AWS account this environment uses."
}

variable "aws_region" {
  default     = "us-east-1"
  description = "The AWS region that resources will be configured in."
}

variable "aws_region_code" {
  default     = "ue1"
  description = "The short code for the AWS region that resources will be configured in."
}

variable "customer" {
  default     = "ExampleCo"
  description = "The customer tag for created resources."
}

variable "product_code" {
  default     = "ev"
  description = "The short code to denote the product the resources are supporting."
}

variable "s3_logging_bucket" {
  description = "The name of the S3 bucket provisioned to store access logs for the account."
}

variable "ssh_public_key" {
  description = "The RSA public key to register as the default deployer infrastructure."
}
