variable "active_server" {
  default     = "a"
  description = "Value: [a|b].  Which of the two private IP assignments correspond to the active server."
}

variable "aws_account_number" {
  description = "The account number of the AWS account this environment uses."
}

variable "backups_policy_arn" {
  description = "The ARN of the IAM policy that allows write access to the S3 backups bucket."
}

variable "customer" {
  description = "Project customer."
}

variable "deploy_policy_arn" {
  description = "The ARN of the IAM policy that allows write access to the S3 deploy bucket."
}

variable "domain_name" {
  description = "DNS domain to deploy resources to."
}

variable "private_ca_arn" {
  description = "The ARN of the Private CA."
}

variable "private_ip" {
  description = "A list of 2 private IPs that will be used for Rundeck servers."
  type        = list(string)
}

variable "rundeck_node_sg_ids" {
  description = "The Rundeck node Security Group IDs from the various environment accounts."
  type        = list(string)
}

variable "server_name" {
  description = "The short name of the Rundeck server."
}

variable "subnets" {
  description = "The subnets of the Rundeck servers."
}

variable "tier" {
  description = "ExampleCo environment to manage."
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
