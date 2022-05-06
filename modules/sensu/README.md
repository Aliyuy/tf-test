# Sensu resources module

This module defines the IAM policies, roles, and instance profiles required for the Sensu server.  It also allocates two Elastic IPs and a DynDNS A record for the server.  

## Variables

`aws_account_number`: The account number of the AWS account this environment uses.

`backups_policy_arn`: The ARN of the IAM policy that allows write access to the S3 backups bucket.

`customer`: Project customer.

`domain_name`: DNS domain to deploy resources to.

`private_ca_arn`: The ARN of the Private CA.

`private_ip`: A list of 2 private IPs that can be used by Sensu server.

`server_name`: The name of the Sensu server.

`tier`: Application environment to manage.

`vpc_cidr_dev`: DEV infrastructure account VPC CIDR range.

`vpc_cidr_stg`: STG infrastructure account VPC CIDR range.

`vpc_cidr_prd`: PRD infrastructure account VPC CIDR range.

`vpc_id`: Target VPC ID.

`vpn_cidrs`: A list of the private IP ranges of the user access VPN servers to allow access from.

`vpn_cidr_mgmt`: A list of the private IP ranges of the management VPN servers to allow access from.

`zone_id`: The Route 53 private zone ID.

## Outputs

`sensu_certificate_arn`: The ARN of the certificate created for the Sensu server.

`sensu_server_fqdn`: The DNS name of the Sensu server, associated with private IP "a".

`sensu_sg_id`: The ID of the Jenkin sserver's security group.

## Import

To import existing resources to manage, use the following commands after defining a module for the desired `tier` as `<tier>_sensu`:

```
$ terraform get

$ terraform import module.<tier>_sensu.aws_iam_role.sensu <TIER>_SENSU

$ terraform import module.<tier>_sensu.aws_iam_instance_profile.sensu <TIER>_SENSU
```

## Dependencies

This module depends on policies managed by the `policies/files-fullname` module to assign access policies for its backups bucket.
