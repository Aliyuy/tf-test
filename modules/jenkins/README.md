# Jenkins resources module

This module defines the IAM policies, roles, and instance profiles required for the Jenkins server.  It also allocates two DNS A records and a CNAME record for the active server.  

## Variables

`aws_account_number`: The account number of the AWS account this environment uses.

`backups_policy_arn`: The ARN of the IAM policy that allows write access to the S3 backups bucket.

`customer`: Project customer.

`domain_name`: DNS domain to deploy resources to.

`private_ca_arn`: The ARN of the Private CA.

`private_ip`: A list of 2 private IPs that can be used by Jenkins server.

`server_name`: The name of the Jenkins server.

`tier`: Application environment to manage.

`vpc_id`: Target VPC ID.

`vpn_cidrs`: A list of the private IP ranges of the user access VPN servers to allow access from.

`vpn_cidr_mgmt`: A list of the private IP ranges of the management VPN servers to allow access from.

`zone_id`: The Route 53 private zone ID.

## Outputs

`jenkins_certificate_arn`: The ARN of the certificate created for the Jenkins server.

`jenkins_server_fqdn`: The DNS name of the Jenkins server, associated with private IP "a".

`jenkins_sg_id`: The ID of the Jenkins server's security group.

`jenkins_worker_sg_id`: The ID of the Jenkins workers' security group.

## Import

To import existing resources to manage, use the following commands after defining a module for the desired `tier` as `<tier>_jenkins`:

```
$ terraform get

$ terraform import module.<tier>_jenkins.aws_iam_role.jenkins <TIER>_JENKINS

$ terraform import module.<tier>_jenkins.aws_iam_instance_profile.jenkins <TIER>_JENKINS
```

## Dependencies

This module depends on policies managed by the `policies/files-fullname` module to assign access policies for its backups bucket.
