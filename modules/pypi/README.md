# PyPI resources module

This module defines the IAM policies, roles, and instance profiles required for the PyPI server.  It also allocates two DNS A records and a CNAME record for the active server.

## Variables

`aws_account_number`: The account number of the AWS account this environment uses.

`bucket_policy_arn`: The ARN of the IAM policy that provides full access to the S3 PyPI bucket.

`customer`: Project customer.

`domain_name`: DNS domain to deploy resources to.

`private_ip`: A list of 2 private IPs that can be used by PyPI servers.

`server_name`: The name of the PyPI server.

`tier`: Application environment to manage.

`vpc_cidr_dev`: DEV infrastructure account VPC ID.

`vpc_cidr_stg`: STG infrastructure account VPC ID.

`vpc_cidr_prd`: PRD infrastructure account VPC ID.

`vpc_id`: Target VPC ID.

`vpn_cidrs`: A list of the private IP ranges of the user access VPN servers to allow access from.

`vpn_cidr_mgmt`: A list of the private IP ranges of the management VPN servers to allow access from.

`zone_id`: The Route 53 private zone ID.

## Outputs

`pypi_server_fqdn`: The DNS name of the PyPI server, associated with the active server.

`pypi_sg_id`: The ID of the PyPI server's security group.

## Dependencies
