# File access policies resources module

This module defines IAM policies that govern read, write, and delete access to a flat file services bucket: `<bucket_name>`

## Variables

`bucket_name`: The name of the target bucket.

## Import

To import existing resources to manage, use the following commands after defining a module for the desired `tier` as `<tier>_<bucket_name>_polciies`:

```
$ terraform get

$ terraform import module.<tier>_<bucket_name>_policies.aws_iam_policy.bucket-fullaccess <arn_of_existing_policy>
$ terraform import module.<tier>_<bucket_name>_policies.aws_iam_policy.bucket_writeaccess <arn_of_existing_policy>
$ terraform import module.<tier>_<bucket_name>_policies.aws_iam_policy.bucket_readonly <arn_of_existing_policy>
```

## Dependencies

This module does not create the bucket named `<bucket_name>`; it is expected to already exist.
