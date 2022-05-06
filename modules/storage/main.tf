locals {
  environment = terraform.workspace
}

resource "aws_s3_bucket" "backups" {
  bucket = "${var.label}-backups"
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  logging {
    target_bucket = var.s3_logging_bucket
    target_prefix = "${var.label}-backups/"
  }

  tags = {
    Terraform = "true"
    Workspace = local.environment
    Name      = "${upper(local.environment)} appliation backups"
    tier      = local.environment
    cust      = var.customer
    service   = "s3_backups"
  }
}

resource "aws_s3_bucket" "deploy" {
  bucket = "${var.label}-deploy"
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  logging {
    target_bucket = var.s3_logging_bucket
    target_prefix = "${var.label}-deploy/"
  }

  tags = {
    Terraform = "true"
    Workspace = local.environment
    Name      = "${upper(local.environment)} third-party software"
    tier      = local.environment
    cust      = var.customer
    service   = "s3_deploy"
  }
}

resource "aws_s3_bucket" "pypi" {
  bucket = "${var.label}-pypi"
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  logging {
    target_bucket = var.s3_logging_bucket
    target_prefix = "${var.label}-pypi/"
  }

  tags = {
    Terraform = "true"
    Workspace = local.environment
    Name      = "${upper(local.environment)} pypi artifacts"
    tier      = local.environment
    cust      = var.customer
    service   = "s3_pypi"
  }
}

