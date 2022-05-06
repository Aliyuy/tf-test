# Terraform configuration for ExampleCo AWS Tooling (ExampleCo Accounts)

This configuration manages tooling resources in the ExampleCo administrative/tooling AWS account.

This is part of a set of TF repos that manage the ExampleCo configurations:

* `tf-admin`: Manages the administrative account. (default workspace)
* `tf-infra`: Manages shared resources in the environment accounts. (`dev|std|prd` workspaces)
* `tf-sites`: Manages site-level resources in the environment accounts. (`<site>-dev|stg|prd` workspaces)

## Resource Lookup

TF environment account configuration repositories that need to reference resources in the admin account should include the following resource in their provider.tf ():

```
data "terraform_remote_state" "tf-admin" {
  backend = "s3"

  config {
    bucket    = "ex-adm-ue1-terraform-state"
    key       = "tf-admin/terraform.tfstate"
    region    = "us-east-1"
  }
}
```

## Usage

The variables for this configuration can be updated from the defaults in files called `terraform.tfvars` (public information) and `secret.auto.tfvars` (sensitive information).  These variables are automatically loaded into the Terraform configuration.  The recommended way to execute Terraform with this Terraform configuration is:

```
$ terraform get
$ terraform init
$ terraform plan -out=./terraform.tfplan
$ terraform apply ./terraform.tfplan
```

The secret variable file is ignored by this repository; it will be stored in a secure location.  It must be copied into the root directory of a clone of this repository to be loaded as described above.

To remove resources from the Terraform state, you can use the `terraform state rm` command as follows:

```
$ terraform state rm aws_s3_bucket.logging    
1 items removed.          
Item removal successful.
$ terraform state rm aws_s3_bucket_policy.logging
1 items removed.
Item removal successful.
```

When `terraform plan` contains a plan that you want to apply, run `terraform plan -out=<path>` (ex: adm.tfplan) to generate an output file to be used with the `terraform apply` command.  This guarantees that the intended plan will be applied.  Note that the output file could contain secrets and shouldn't be added to version control.  

[Terraform plan docs](https://www.terraform.io/docs/commands/plan.html)

Once the `.tfplan` is generated, run `terraform apply <path to plan file>` to apply it.

[Terraform apply docs](https://www.terraform.io/docs/commands/apply.html)

## Resources

The `utility/bootstrap` configuration configures Terraform State resources and the Terraform admistrative IAM role.

# VPC Peering

This configuration defines the resources required to manage VPC peering between the admin account managed VPC and the managed VPCs of the environment accounts:

*	ex-adm (10.0.0.0/16) <-> ex-dev (10.12.0.0/16)
*	ex-adm (10.0.0.0/16) <-> ex-stg (10.13.0.0/16)
*	ex-adm (10.0.0.0/16) <-> ex-prd (10.14.0.0/16)

## Prerequisites

* Terraform >= 1.0 < 2.0

* The administrator running Terraform against this configuration must belong to the administrator group that is permitted to manage resources in the target AWS account.

* An S3 bucket, DynamoDB table, and KMS key is required for the Terraform remote state backend.  These are provisioned using the configuration in the `utility/bootstrap` directory.  See the `backend.tf` and `provider.tf` for usage.  The administrator or process running Terraform must have access to these resources; they can be granted by assuming the `TerraformAssumedIamRole`.

## Variables

* `account_code` *(Default: `ru`)*: The short code for the AWS account this environment uses.

* `aws_account_number`: The account number for the AWS account this environment uses.

* `aws_region` *(Default: `us-east-1`)*:  The AWS region that resources will be configured in.

* `aws_region_code` *(Default: `ue1`)*: The short code for the AWS region that resources will be configured in.

* `backups_bucket_id`: The name of the S3 backups bucket.

* `customer` *(Default: `ExampleCo`)*: The customer tag for created resources.

* `ca_domain_name` *(Default: `ExampleCo.internal`)*: The DNS name for the Private CA.

* `domain_name` *(Default: `adm.ExampleCo.internal`)*: The private DNS domain this account hosts.

* `jenkins_private_ip`: A list of 2 private IPs that will be used for Jenkins servers.

* `organization`: Organization name for Private CA.

* `organization_unit`: Organization unit name for Private CA.

* `organization_country`: Organization country name for Private CA.

* `organization_state`: Organization state name for Private CA.

* `organization_locality`: Organization locality name for Private CA.

* `private_cidr` *(Default: `10.0.0.0/8`)*: The private IP CIDR range of the VPN.

* `product_code` *(Default: `ev`)*: The short code to denote the product the resources are supporting.

* `prometheus_private_ip`: A list of 2 private IPs that will be used for Prometheus servers.

* `pypi_private_ip`: A list of 2 private IPs that will be used for PyPI servers.

* `route53_resolver_ip`: A list of 2 private IPs that will be used for the Route 53 inbound resolver.

* `route53_outbound_resolver_ip`: A list of 2 private IPs that will be used for the Route 53 outbound resolver.

* `rundeck_private_ip`: A list of 2 private IPs that will be used for Rundeck servers.

* `s3_logging_bucket`: The name of the S3 bucket provisioned to store access logs for the account.

* `sensu_private_ip`: A list of 2 private IPs that will be used for Sensu servers.

* `ssh_public_key`: The RSA public key to register as the default deployment EC2 key pair in the managed AWS account.

* `subnets_network` The network subnets to use for application load balancer connections.

* `subnets_public` The public subnets to use for Application Load Balancer connections.

* `vpc_cidr_dev`: VPC CIDR range for the ex-dev environment account.

* `vpc_cidr_prd`: VPC CIDR range for the ex-prd environment account.

* `vpc_cidr_stg`: VPC CIDR range for the ex-stg environment account.

* `vpc_id`: Target VPC ID.

* `vpc_id_dev`: Target VPC ID for the ex-dev environment account.

* `vpc_id_prd`: Target VPC ID for the ex-prd environment account.

* `vpc_id_stg`: Target VPC ID for the ex-stg environment account.

* `vpn_cidrs`: The Lower and Upper ExampleCo VPN internal CIDR ranges.

* `vpn_cidr_upper`: The Upper ExampleCo VPN internal CIDR ranges.

## Outputs

`dns_forwarding_rules_arn`: (*list*) The ARN of the shared DNS forwarding rules to be implemented by managed environment accounts in `tf-infra`.

`ec2_keypair_name`: The name of the default EC2 key pair.

`jenkins_server_fqdn`: The DNS name of the Jenkins server.

`jenkins_sg_id`: The ID of the Jenkins server's security group.

`jenkins_worker_sg_id`: The ID of the Jenkins workers' security group.

`private_ca_arn`: The ARN of the Private CA Root.

`private_ca_issuing_arn`: The ARN of the Private Subordinate/Issuing CA.

`prometheus_server_fqdn`: The DNS name of the Prometheus server.

`prometheus_sg_id`: The ID of the Prometheus security group.

`pypi_server_fqdn`: The DNS name of the PyPI server.

`pypi_sg_id`: The ID of the PyPI security group.

`route_53_private_zone_id`: The zone_id of the Route 53 Private Zone.

`rundeck_server_fqdn`: The DNS name of the Rundeck server.

`rundeck_sg_id`: The ID of the Rundeck security group.

`sensu_server_fqdn`: The DNS name of the Sensu server.

`sensu_sg_id`: The ID of the Sensu security group.

`backups_bucket_id`
`deploy_bucket_id`
`pypi_bucket_id`

## Prerequisites

The ExampleCo wildcard certificate for the admin AWS account must be created in AWS Certificate Manager (ACM) before it can be used by this configuration.
