locals {
  environment = "adm"
  prefix      = "${var.product_code}-${var.account_code}-adm-${var.aws_region_code}"
}

# S3 Bucket for Terraform State
resource "aws_s3_bucket" "terraform_state" {
  bucket = "${local.prefix}-terraform-state"
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }

  logging {
    target_bucket = "ex-adm-ue1-s3-access-logs"
    target_prefix = "${local.prefix}-terraform-state/"
  }

  versioning {
    enabled = true
  }

  tags = {
    Terraform = "true"
    Workspace = local.environment
    Name      = "${var.customer} Terraform State"
    tier      = local.environment
    cust      = var.customer
    service   = "s3_terraform_state"
  }
}

# DynamoDB table for Terraform State locking

resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = "${local.prefix}-terraform-lock"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Terraform = "true"
    Workspace = local.environment
    Name      = "${var.customer} Terraform State"
    tier      = local.environment
    cust      = var.customer
    service   = "dynamodb_terraform_state"
  }
}

# Policies that allow access to Terraform State resources

data "aws_iam_policy_document" "terraform_state_bucket_writeaccess" {
  statement {
    sid = "1"

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::${local.prefix}-terraform-state",
    ]
  }

  statement {
    sid = "2"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]

    resources = [
      "arn:aws:s3:::${local.prefix}-terraform-state/*",
    ]
  }
}

resource "aws_iam_policy" "terraform_state_bucket_writeaccess" {
  name   = "TerraformStateBucketWriteAccess"
  path   = "/"
  policy = data.aws_iam_policy_document.terraform_state_bucket_writeaccess.json
}

data "aws_iam_policy_document" "terraform_state_lock_fullaccess" {
  statement {
    sid = "1"

    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
    ]

    resources = [
      "arn:aws:dynamodb:*:*:table/${local.prefix}-terraform-lock",
    ]
  }
}

resource "aws_iam_policy" "terraform_state_lock_fullaccess" {
  name   = "TerraformStateLockFullAccess"
  path   = "/"
  policy = data.aws_iam_policy_document.terraform_state_lock_fullaccess.json
}

# Policy that allows administrative access to defined services

data "aws_iam_policy_document" "terraform_admin_fullaccess" {
  statement {
    sid = "AllowAll"

    actions = [
      "acm:*",
      "acm-pca:*",
      "apigateway:*",
      "application-autoscaling:*",
      "athena:*",
      "cloudfront:*",
      "cloudtrail:*",
      "cloudwatch:*",
      "dynamodb:*",
      "ec2:*",
      "elasticloadbalancing:*",
      "glue:*",
      "iam:*",
      "kms:*",
      "lambda:*",
      "logs:*",
      "ram:*",
      "rds:*",
      "redshift:*",
      "route53:*",
      "route53resolver:*",
      "s3:*",
      "secretsmanager:*",
      "transfer:*",
      "waf:*",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "terraform_admin_fullaccess" {
  name   = "TerraformAdminFullAccess"
  path   = "/"
  policy = data.aws_iam_policy_document.terraform_admin_fullaccess.json
}

# IAM role to attach to EC2 Terraform builders

resource "aws_iam_role" "terraform_implicit_role" {
  name = "TerraformImplicitIamRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Terraform = "true"
    Workspace = local.environment
    Name      = "${var.customer} ${upper(local.environment)} Terraform Implicit Role"
    tier      = local.environment
    cust      = var.customer
    service   = "iam_terraform_implicit_role"
  }
}

# IAM policy to give implicit role permission to assume broad IAM Role

resource "aws_iam_policy" "terraform_permit_sts_assume" {
  name = "TerraformPolicyPermitStsAssume"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": "${aws_iam_role.terraform_admin_role.arn}"
    }
  ]
}
EOF

  lifecycle {
    prevent_destroy = true
  }
}

# Attach IAM assume role to policy
resource "aws_iam_role_policy_attachment" "terraform_attach_implicit_role_to_sts_assume_policy" {
  role       = aws_iam_role.terraform_implicit_role.name
  policy_arn = aws_iam_policy.terraform_permit_sts_assume.arn

  lifecycle {
    prevent_destroy = true
  }
}

# Create IAM instance profile so ec2 can associate to it
resource "aws_iam_instance_profile" "terraform_implicit_instance_profile" {
  name = aws_iam_role.terraform_implicit_role.name
  role = aws_iam_role.terraform_implicit_role.name
}

# IAM role for Terraform infrastructure management

resource "aws_iam_role" "terraform_admin_role" {
  name = "TerraformAssumedIamRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": [
          "${aws_iam_role.terraform_implicit_role.arn}",
          "${aws_iam_user.terraform_admin_user.arn}"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    Terraform = "true"
    Workspace = local.environment
    Name      = "${var.customer} ${upper(local.environment)} Terraform Admin Role"
    tier      = local.environment
    cust      = var.customer
    service   = "iam_terraform_admin_role"
  }
}

resource "aws_iam_role_policy_attachment" "terraform_state_bucket_writeaccess" {
  role       = aws_iam_role.terraform_admin_role.name
  policy_arn = aws_iam_policy.terraform_state_bucket_writeaccess.arn
}

resource "aws_iam_role_policy_attachment" "terraform_state_lock_fullaccess" {
  role       = aws_iam_role.terraform_admin_role.name
  policy_arn = aws_iam_policy.terraform_state_lock_fullaccess.arn
}

resource "aws_iam_role_policy_attachment" "terraform_admin_fullaccess" {
  role       = aws_iam_role.terraform_admin_role.name
  policy_arn = aws_iam_policy.terraform_admin_fullaccess.arn
}

# Allow the TF implicit role to manage resources in Og (dev) account
resource "aws_iam_role_policy" "terraform_dev_admin_policy" {
  name = "Allow-Assume-Terraform-Role-in-Og"
  role = aws_iam_role.terraform_implicit_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Resource": "arn:aws:iam::790668890258:role/TerraformAssumedIamRole"
  }
}
EOF
}

# Allow the TF implicit role to manage resources in Rh (stg) account
resource "aws_iam_role_policy" "terraform_stg_admin_policy" {
  name = "Allow-Assume-Terraform-Role-in-Rh"
  role = aws_iam_role.terraform_implicit_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Resource": "arn:aws:iam::788051111186:role/TerraformAssumedIamRole"
  }
}
EOF
}

# Allow the TF implicit role to manage resources in Ra (prd) account
resource "aws_iam_role_policy" "terraform_prd_admin_policy" {
  name = "Allow-Assume-Terraform-Role-in-Ra"
  role = aws_iam_role.terraform_implicit_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Resource": "arn:aws:iam::537777728142:role/TerraformAssumedIamRole"
  }
}
EOF
}

# Allow OneLogin RuAdmin role to perform Terraform infrastructure management - deprecated

data "aws_iam_role" "account_admin_role" {
  name = "RuAdmin"
}

resource "aws_iam_role_policy_attachment" "terraform_state_bucket_writeaccess_account_admin" {
  role       = data.aws_iam_role.account_admin_role.name
  policy_arn = aws_iam_policy.terraform_state_bucket_writeaccess.arn
}

resource "aws_iam_role_policy_attachment" "terraform_state_lock_fullaccess_account_admin" {
  role       = data.aws_iam_role.account_admin_role.name
  policy_arn = aws_iam_policy.terraform_state_lock_fullaccess.arn
}

resource "aws_iam_role_policy_attachment" "terraform_admin_fullaccess_account_admin" {
  role       = data.aws_iam_role.account_admin_role.name
  policy_arn = aws_iam_policy.terraform_admin_fullaccess.arn
}

# Allow Onelogin RuAdmin role to manage resources in Og (dev) account - deprecated
resource "aws_iam_role_policy" "terraform_dev_account_admin_policy" {
  name = "Allow-Assume-Terraform-Role-in-Og"
  role = data.aws_iam_role.account_admin_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Resource": "arn:aws:iam::790668890258:role/TerraformAssumedIamRole"
  }
}
EOF
}

# Allow OneLogin RuAdmin role to manage resources in Rh (stg) account - deprecated
resource "aws_iam_role_policy" "terraform_stg_account_admin_policy" {
  name = "Allow-Assume-Terraform-Role-in-Rh"
  role = data.aws_iam_role.account_admin_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Resource": "arn:aws:iam::788051111186:role/TerraformAssumedIamRole"
  }
}
EOF
}

# Allow Onelogin RuAdmin role to manage resources in Ra (prd) account - deprecated
resource "aws_iam_role_policy" "terraform_prd_account_admin_policy" {
  name = "Allow-Assume-Terraform-Role-in-Ra"
  role = data.aws_iam_role.account_admin_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Resource": "arn:aws:iam::537777728142:role/TerraformAssumedIamRole"
  }
}
EOF
}

# IAM group/user for Terraform infrastructure management

resource "aws_iam_group" "terraform_admin_group" {
  name = "Terraform"
}

# Allow this group S3 backend bucket access without assuming another role - deprecated
resource "aws_iam_group_policy_attachment" "terraform_state_bucket_writeaccess" {
  group      = aws_iam_group.terraform_admin_group.name
  policy_arn = aws_iam_policy.terraform_state_bucket_writeaccess.arn
}

# Allow this group S3 backend state lock access without assuming another role - deprecated
resource "aws_iam_group_policy_attachment" "terraform_state_lock_fullaccess" {
  group      = aws_iam_group.terraform_admin_group.name
  policy_arn = aws_iam_policy.terraform_state_lock_fullaccess.arn
}

# Allow this group full TF admin access without assuming another role - deprecated
resource "aws_iam_group_policy_attachment" "terraform_admin_fullaccess" {
  group      = aws_iam_group.terraform_admin_group.name
  policy_arn = aws_iam_policy.terraform_admin_fullaccess.arn
}

# Allow users in this group to manage resources in Ru (adm) account via assumed role
resource "aws_iam_group_policy_attachment" "terraform_attach_to_sts_assume_policy" {
  group      = aws_iam_group.terraform_admin_group.name
  policy_arn = aws_iam_policy.terraform_permit_sts_assume.arn

  lifecycle {
    prevent_destroy = true
  }
}

# Allow this group to manage resources in Og (dev) account
resource "aws_iam_group_policy" "terraform_dev_admin_policy" {
  name  = "Allow-Assume-Terraform-Role-in-Og"
  group = aws_iam_group.terraform_admin_group.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Resource": "arn:aws:iam::790668890258:role/TerraformAssumedIamRole"
  }
}
EOF
}

# Allow this group to manage resources in Rh (stg) account
resource "aws_iam_group_policy" "terraform_stg_admin_policy" {
  name  = "Allow-Assume-Terraform-Role-in-Rh"
  group = aws_iam_group.terraform_admin_group.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Resource": "arn:aws:iam::788051111186:role/TerraformAssumedIamRole"
  }
}
EOF
}

# Allow this group to manage resources in Ra (prd) account
resource "aws_iam_group_policy" "terraform_prd_admin_policy" {
  name  = "Allow-Assume-Terraform-Role-in-Ra"
  group = aws_iam_group.terraform_admin_group.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Resource": "arn:aws:iam::537777728142:role/TerraformAssumedIamRole"
  }
}
EOF
}

resource "aws_iam_user" "terraform_admin_user" {
  name = "terraform"

  tags = {
    Terraform = "true"
    Workspace = local.environment
    Name      = "${var.customer} ${upper(local.environment)} Terraform Admin User"
    tier      = local.environment
    cust      = var.customer
    service   = "iam_terraform_admin_user"
  }
}

resource "aws_iam_user_group_membership" "terraform" {
  user = aws_iam_user.terraform_admin_user.name

  groups = [
    aws_iam_group.terraform_admin_group.name,
  ]
}
