data "aws_vpc" "myvpc" {
  id = var.vpc_id
}

# Policy document that grants an entity permission to assume the role
data "aws_iam_policy_document" "instance-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "rundeck" {
  name               = upper("${var.tier}_RUNDECK")
  assume_role_policy = data.aws_iam_policy_document.instance-assume-role-policy.json
  description        = "Allows ${upper(var.tier)} Rundeck servers to access required resources."
}

data "aws_iam_policy" "terraform_permit_sts_assume_terraform" {
  arn = "arn:aws:iam::${var.aws_account_number}:policy/TerraformPolicyPermitStsAssume"
}

# Attach Terraform IAM assumed role to Rundeck policy
resource "aws_iam_role_policy_attachment" "rundeck_attach_implicit_role_to_sts_assume_policy" {
  role       = aws_iam_role.rundeck.name
  policy_arn = data.aws_iam_policy.terraform_permit_sts_assume_terraform.arn

  lifecycle {
    prevent_destroy = true
  }
}

# Attach SSM-related policies to Rundeck role
resource "aws_iam_role_policy_attachment" "rundeck_attach_ssm_policy" {
  role       = aws_iam_role.rundeck.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "rundeck_attach_cloudwatch_agent_policy" {
  role       = aws_iam_role.rundeck.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"

  lifecycle {
    prevent_destroy = true
  }
}

# Attach S3 backups policy to Rundeck role
resource "aws_iam_role_policy_attachment" "rundeck_attach_backups_policy" {
  role       = aws_iam_role.rundeck.name
  policy_arn = var.backups_policy_arn

  lifecycle {
    prevent_destroy = true
  }
}

# Attach S3 deploy bucket policy to Rundeck role
resource "aws_iam_role_policy_attachment" "rundeck_attach_deploy_policy" {
  role       = aws_iam_role.rundeck.name
  policy_arn = var.deploy_policy_arn

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_instance_profile" "rundeck" {
  name = aws_iam_role.rundeck.name
  role = aws_iam_role.rundeck.name
}

# Security group for Rundeck servers

resource "aws_security_group" "rundeck" {
  name        = "${upper(var.tier)}-Rundeck"
  description = "Rundeck ${upper(var.tier)} servers"
  vpc_id      = var.vpc_id

  ingress {
    # SSH Management Traffic
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = flatten([
      [data.aws_vpc.myvpc.cidr_block],
      var.vpn_cidr_mgmt
    ])
  }

  ingress {
    # TLS (Rundeck via Nginx Reverse Proxy)
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = flatten([
      [data.aws_vpc.myvpc.cidr_block],
      var.vpn_cidrs
    ])
    security_groups = var.rundeck_node_sg_ids
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${upper(var.tier)}-Rundeck"
    Terraform = "true"
    tier      = var.tier
    cust      = var.customer
    service   = "rundeck_sg"
  }
}

# DNS Entries for Rundeck servers
resource "aws_route53_record" "rundeck_a" {
  zone_id = var.zone_id
  name    = "${var.server_name}-a"
  type    = "A"
  ttl     = 3600
  records = [var.private_ip[0]]
}

resource "aws_route53_record" "rundeck_b" {
  zone_id = var.zone_id
  name    = "${var.server_name}-b"
  type    = "A"
  ttl     = 3600
  records = [var.private_ip[1]]
}

resource "aws_route53_record" "rundeck" {
  zone_id = var.zone_id
  name    = var.server_name

  type    = "CNAME"
  ttl     = 3600
  records = ["${var.server_name}-${var.active_server}.${var.domain_name}"]
}

# Private certificate for Rundeck server
resource "aws_acm_certificate" "rundeck" {
  domain_name               = "rundeck.${var.domain_name}"
  certificate_authority_arn = var.private_ca_arn

  subject_alternative_names = [
    "${var.server_name}-${var.active_server}.${var.domain_name}",
  ]

  tags = {
    Name      = "${upper(var.tier)}-Rundeck certificate"
    Terraform = "true"
    tier      = var.tier
    cust      = var.customer
    service   = "rundeck_cert"
  }
}
