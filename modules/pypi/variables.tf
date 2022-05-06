variable "active_server" {
  default     = "a"
  description = "Value: [a|b].  Which of the two private IP assignments correspond to the active server."
}

variable "aws_account_number" {
  description = "The account number of the AWS account this environment uses."
}

variable "bucket_policy_arn" {
  description = "The ARN of the IAM policy that provides full access to the S3 PyPI bucket."
}

variable "customer" {
  description = "Project customer."
}

variable "domain_name" {
  description = "DNS domain to deploy resources to."
}

variable "private_ip" {
  description = "A list of 2 private IPs that will be used for PyPI servers."
  type        = list(string)
}

variable "server_name" {
  description = "The short name of the PyPI server."
}

variable "subnets" {
  description = "The subnets of the PyPI servers."
}

variable "tier" {
  description = "ExampleCo environment to manage."
}

variable "vpc_cidr_dev" {
  description = "DEV infrastructure account VPC CIDR range."
}

variable "vpc_cidr_stg" {
  description = "STG infrastructure account VPC CIDR range."
}

variable "vpc_cidr_prd" {
  description = "PRD infrastructure account VPC CIDR range."
}

variable "vpc_id" {
  description = "Target VPC ID."
}

variable "vpn_cidrs" {
  description = "A list of the private IP ranges of the user access VPN servers to allow access from."
  type        = list(string)
}

variable "vpn_cidr_mgmt" {
  description = "A list of the private IP ranges of the management VPN servers to allow access from."
  type        = list(string)
}

variable "zone_id" {
  description = "The Route 53 private zone ID."
}
