# ExampleCo Terraform storage module

This module defines the default storage resources to provision in the environment account.

S3 buckets:

* Backups bucket: Storage location for application backup files.

## Inputs

* `customer`: Customer name included in tags.

* `label`: Prefix used in bucket names.

## Outputs

* `backups_bucket_id`
* `deploy_bucket_id`
* `pypi_bucket_id`
