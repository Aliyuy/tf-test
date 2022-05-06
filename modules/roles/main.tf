locals {
  environment = terraform.workspace
}

# Policy docs
data "aws_iam_policy_document" "instance-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "build" {
  name               = "ex-BUILD"
  assume_role_policy = data.aws_iam_policy_document.instance-assume-role-policy.json
  description        = "Allows ${upper(local.environment)} ExampleCo build servers full access to deploy S3 bucket."
}

resource "aws_iam_role_policy_attachment" "build-deploy-fullaccess" {
  role       = aws_iam_role.build.name
  policy_arn = var.deploy_fullaccess_policy_arn
}

resource "aws_iam_instance_profile" "build" {
  name = aws_iam_role.build.name
  role = aws_iam_role.build.name
}
