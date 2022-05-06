# ExampleCo Terraform roles module

This module defines the IAM roles to provision for EC2 resources in the admin account that require access to S3 buckets and other resources.

ExampleCo build role:
* `ex-Build` (EC2): Full access to deploy bucket.

## Inputs

* `deploy_fullaccess_policy_arn`

## Outputs

* `build_iam_role_name`
