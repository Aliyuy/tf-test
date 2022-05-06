# Template for full access to bucket
data "aws_iam_policy_document" "bucket_fullaccess" {
  statement {
    sid = "1"

    actions = [
      "s3:List*",
    ]

    resources = [
      "arn:aws:s3:::${var.bucket_name}",
    ]
  }

  statement {
    sid = "2"

    actions = [
      "s3:Get*",
      "s3:Put*",
      "s3:Delete*",
    ]

    resources = [
      "arn:aws:s3:::${var.bucket_name}/*",
    ]
  }
}

# Template for write access to bucket
data "aws_iam_policy_document" "bucket_writeaccess" {
  statement {
    sid = "1"

    actions = [
      "s3:List*",
    ]

    resources = [
      "arn:aws:s3:::${var.bucket_name}",
    ]
  }

  statement {
    sid = "2"

    actions = [
      "s3:Get*",
      "s3:Put*",
    ]

    resources = [
      "arn:aws:s3:::${var.bucket_name}/*",
    ]
  }
}

# Template for read access to bucket
data "aws_iam_policy_document" "bucket_readonly" {
  statement {
    sid = "1"

    actions = [
      "s3:List*",
    ]

    resources = [
      "arn:aws:s3:::${var.bucket_name}",
    ]
  }

  statement {
    sid = "2"

    actions = [
      "s3:Get*",
    ]

    resources = [
      "arn:aws:s3:::${var.bucket_name}/*",
    ]
  }
}

# Policy document that grants an entity full access to the bucket
resource "aws_iam_policy" "bucket-fullaccess" {
  name        = "${var.bucket_name}.S3.FullAccess"
  path        = "/"
  description = "Provides programmatic read-write-delete access to ${var.bucket_name} bucket"
  policy      = data.aws_iam_policy_document.bucket_fullaccess.json
}

# Policy document that grants an entity write access to the bucket
resource "aws_iam_policy" "bucket-writeaccess" {
  name        = "${var.bucket_name}.S3.WriteAccess"
  path        = "/"
  description = "Provides programmatic read-write access to ${var.bucket_name} bucket"
  policy      = data.aws_iam_policy_document.bucket_writeaccess.json
}

# Policy document that grants an entity read-only access to the datasets bucket
resource "aws_iam_policy" "bucket-readonly" {
  name        = "${var.bucket_name}.S3.ReadOnly"
  path        = "/"
  description = "Provides programmatic read-only access to ${var.bucket_name} bucket"
  policy      = data.aws_iam_policy_document.bucket_readonly.json
}
