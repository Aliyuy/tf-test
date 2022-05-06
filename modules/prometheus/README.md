# Prometheus resources module

This module defines the IAM policies, roles, and instance profiles required for the Prometheus servers.  It also allocates two DNS A records and a CNAME record for the active server.  Because the Prometheus server monitors all EC2 resources in its account, its IAM role leverages the AWS-managed AmazonEC2ReadOnlyAccess policy to provide access.

## Variables

`aws_account_number`: The account number of the AWS account this environment uses.

`customer`: Project customer.

`domain_name`: DNS domain to deploy resources to.

`private_ip`: A list of 2 private IPs that can be used by Prometheus servers.

`server_name`: The name of the Prometheus server.

`tier`: Application environment to manage.

`vpc_cidr_dev`: DEV infrastructure account VPC CIDR range.

`vpc_cidr_stg`: STG infrastructure account VPC CIDR range.

`vpc_cidr_prd`: PRD infrastructure account VPC CIDR range.

`vpc_id`: Target VPC ID.

`vpn_cidrs`: A list of the private IP ranges of the user access VPN servers to allow access from.

`vpn_cidr_mgmt`: A list of the private IP ranges of the management VPN servers to allow access from.

`zone_id`: The Route 53 private zone ID.

## Outputs

`prometheus_server_fqdn`: The DNS name of the Prometheus server, associated with the active server.

`prometheus_sg_id`: The ID of the Prometheus server's security group.

## Dependencies
