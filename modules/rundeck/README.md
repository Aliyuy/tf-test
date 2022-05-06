# Rundeck resources module

This module defines the IAM policies, roles, and instance profiles required for the Rundeck servers.  It also allocates two Elastic IPs and a DynDNS A record for the server.  Because the Rundeck server manages AWS resources in all ExampleCo accounts, its IAM role leverages the existing Terraform roles to elevate its privileges.

## Variables

`aws_account_number`: The account number of the AWS account this environment uses.

`backups_policy_arn`: The ARN of the IAM policy that allows write access to the S3 backups bucket.

`customer`: Project customer.

`deploy_policy_arn`: The ARN of the IAM policy that allows write access to the S3 deploy bucket.

`domain_name`: DNS domain to deploy resources to.

`private_ca_arn`: The ARN of the Private CA.

`private_ip`: A list of 2 private IPs that can be used by Rundeck servers.

`rundeck_node_sg_ids`: The Rundeck node Security Group IDs from the various environment accounts.

`server_name`: The name of the Rundeck server.

`tier`: Application environment to manage.

`vpc_id`: Target VPC ID.

`vpn_cidrs`: A list of the private IP ranges of the user access VPN servers to allow access from.

`vpn_cidr_mgmt`: A list of the private IP ranges of the management VPN servers to allow access from.

`zone_id`: The Route 53 private zone ID.

## Outputs

`rundeck_server_fqdn`: The DNS name of the Rundeck server, associated with Elastic IP "a".

`rundeck_sg_id`: The ID of the Rundeck server's security group.

## Import

To import existing resources to manage, use the following commands after defining a module for the desired `tier` as `<tier>_rundeck`:

```
$ terraform get

$ terraform import module.<tier>_rundeck.aws_iam_role.rundeck <TIER>_RUNDECK

$ terraform import module.<tier>_rundeck.aws_iam_instance_profile.rundeck <TIER>_RUNDECK
```

## Dependencies

This module depends on policies managed by the `policies/files-fullname` module to assign access policies for its backups bucket.
