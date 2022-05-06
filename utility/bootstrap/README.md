# ExampleCo tf-admin bootstrap utility

This configuration defines the resources required to allow EC2 build nodes to assume an IAM role in the infrastructure account to perform configuration management.

It also allows the pre-defined RuAdmin role to assume the Terraform Administrative roles in the managed AWS accounts.

This configuration must be run by an administrator of the AWS account and uses local Terraform state, as it is managing the state resources used by the main configuration of this repository.

## Workspaces

The default Terraform workspace will be used to manage resources in the assigned AWS infrastructure account:

* ExampleCo ADMIN/TOOLING account ("Ru: adm") us-east-1 resources

## Usage

Invoke this configuration as follows:
```
$ cd tf-infra/utility/bootstrap/
$ terraform init
$ terraform plan \
  -var-file="../../terraform.tfvars" \
  -out="./terraform.tfplan"
$ terraform apply ./terraform.tfplan
```

## Variables

* `account_code`: The short code for the AWS account this environment uses.

* `aws_account_number`: The account number of the AWS account this environment uses.

* `aws_region` *(Default: `us-east-1`)*:  The AWS region that resources will be configured in.

* `aws_region_code` *(Default: `ue1`)*: The short code for the AWS region that resources will be configured in.

* `customer` *(Default: `ExampleCo`)*: The customer tag for created resources.

* `product_code` *(Default: `ev`)*: The short code to denote the product the resources are supporting.

* `s3_logging_bucket`: Unused.  Placeholder for a variable declared in terraform.tfvars.

* `ssh_public_key`: Unused.  Placeholder for a variable declared in terraform.tfvars.

## Outputs

`terraform_admin_role_arn`: The ARN of the IAM role created to allow Terraform to manage infrastructure in this AWS account.

`terraform_admin_user_arn`: The ARN of the IAM user created to allow Terraform to manage infrastructure in this AWS account.

`terraform_implicit_role_arn`: The ARN of the IAM role created to allow EC2 Terraform builders to assume the Terraform admin role.

`terraform_state_bucket_id`: The name of the Terraform State S3 bucket in this AWS account.

`terraform_state_dynamodb_table_id`: The name of the Terraform State DynamoDB lock table in this AWS account.

## Dependencies
