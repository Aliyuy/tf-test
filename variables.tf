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

variable "environment_aws_account_number" {
  type = map(string)

  default = {
    dev = "790668890258",
    stg = "788051111186",
    prd = "537777728142",
  }

  description = "The account numbers of the AWS accounts this environment manages."
}

variable "ca_domain_name" {
  default     = "ExampleCo.internal"
  description = "Domain name for the Private CA and Route 53 resolvers."
}

variable "domain_name" {
  default     = "adm.ExampleCo.internal"
  description = "Domain name for the VPC's internal DNS zone."
}

variable "jenkins_private_ip" {
  description = "A list of 2 private IPs that will be used for Jenkins servers."
  type        = list(string)
}

variable "organization" {
  default     = "ExampleCo"
  description = "Organization name for Private CA."
}

variable "organization_unit" {
  default     = "ExampleCo"
  description = "Organization unit name for Private CA."
}

variable "organization_country" {
  default     = "US"
  description = "Organization country name for Private CA."
}

variable "organization_state" {
  default     = "New York"
  description = "Organization state name for Private CA."
}

variable "organization_locality" {
  default     = "New York"
  description = "Organization locatlity name for Private CA."
}

variable "private_cidr" {
  default     = "10.0.0.0/8"
  description = "The VPN CIDR range."
}

variable "product_code" {
  description = "The short code to denote the product the resources are supporting."
}

variable "prometheus_private_ip" {
  description = "A list of 2 private IPs that will be used for Prometheus servers."
  type        = list(string)
}

variable "pypi_private_ip" {
  description = "A list of 2 private IPs that will be used for PyPI servers."
  type        = list(string)
}

variable "route53_resolver_ip" {
  description = "A list of 2 private IPs that will be used for the Route 53 inbound resolver."
  type        = list(string)
}

variable "route53_outbound_resolver_ip" {
  description = "A list of 2 private IPs that will be used for the Route 53 outbound resolver."
  type        = list(string)
}

variable "rundeck_private_ip" {
  description = "A list of 2 private IPs that will be used for Rundeck servers."
  type        = list(string)
}

variable "s3_logging_bucket" {
  description = "The name of the S3 bucket provisioned to store access logs for the account."
}

variable "sensu_private_ip" {
  description = "A list of 2 private IPs that will be used for Sensu servers."
  type        = list(string)
}

variable "ssh_public_key" {
  description = "The RSA public key to register as the default deployer infrastructure."
}

variable "subnets_network" {
  type        = list(string)
  description = "The network subnets to use for application load balancer connections."
}

variable "subnets_public" {
  type        = list(string)
  description = "The public subnets to use for Application Load Balancer connections."
}

variable "vpc_cidr_dev" {
  description = "VPC CIDR range for the ex-dev environment account."
}

variable "vpc_cidr_prd" {
  description = "VPC CIDR range for the ex-prd environment account."
}

variable "vpc_cidr_stg" {
  description = "VPC CIDR range for the ex-stg environment account."
}

variable "vpc_id" {
  description = "Target VPC ID."
}

variable "vpc_id_dev" {
  description = "Target VPC ID for the ex-dev environment account."
}

variable "vpc_id_prd" {
  description = "Target VPC ID for the ex-prd environment account."
}

variable "vpc_id_stg" {
  description = "Target VPC ID for the ex-stg environment account."
}

variable "vpn_cidrs" {
  type = list(string)
  default = [
    "10.1.1.0/24",
    "10.1.2.0/24",
  ]
  description = "The VPN internal CIDR ranges."
}

variable "vpn_cidr_upper" {
  type = list(string)
  default = [
    "10.1.2.0/24",
  ]
  description = "The Upper VPN internal CIDR ranges."
}
