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

resource "aws_iam_role" "pypi" {
  name               = upper("${var.tier}_pypi")
  assume_role_policy = data.aws_iam_policy_document.instance-assume-role-policy.json
  description        = "Allows ${upper(var.tier)} PyPI servers to access required resources."
}

data "aws_iam_policy" "pypi_full_access" {
  arn = var.bucket_policy_arn
}

# Attach PyPI role to S3 pypi bucket write policy
resource "aws_iam_role_policy_attachment" "pypi" {
  role       = aws_iam_role.pypi.name
  policy_arn = data.aws_iam_policy.pypi_full_access.arn

  // lifecycle {
  //   prevent_destroy = true
  // }
}

# Attach SSM-related policies to PyPI role
resource "aws_iam_role_policy_attachment" "pypi_attach_ssm_policy" {
  role       = aws_iam_role.pypi.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "pypi_attach_cloudwatch_agent_policy" {
  role       = aws_iam_role.pypi.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_instance_profile" "pypi" {
  name = aws_iam_role.pypi.name
  role = aws_iam_role.pypi.name
}

# Security group for pypi servers

resource "aws_security_group" "pypi" {
  name        = "${upper(var.tier)}-PYPI"
  description = "PyPI ${upper(var.tier)} servers"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = flatten([
      [data.aws_vpc.myvpc.cidr_block],
      var.vpn_cidr_mgmt
    ])
    description = "SSH from Internal"
  }

  ingress {
    from_port = 6543
    to_port   = 6543
    protocol  = "tcp"
    cidr_blocks = flatten([
      [data.aws_vpc.myvpc.cidr_block],
      [var.vpc_cidr_dev],
      [var.vpc_cidr_stg],
      [var.vpc_cidr_prd],
      var.vpn_cidrs
    ])
    description = "PyPI from Internal"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${upper(var.tier)}-PYPI"
    Terraform = "true"
    tier      = var.tier
    cust      = var.customer
    service   = "pypi_sg"
  }
}

# DNS Entries for pypi servers
resource "aws_route53_record" "pypi_a" {
  zone_id = var.zone_id
  name    = "${var.server_name}-a"
  type    = "A"
  ttl     = 3600
  records = [var.private_ip[0]]
}

resource "aws_route53_record" "pypi_b" {
  zone_id = var.zone_id
  name    = "${var.server_name}-b"
  type    = "A"
  ttl     = 3600
  records = [var.private_ip[1]]
}

resource "aws_route53_record" "pypi" {
  zone_id = var.zone_id
  name    = var.server_name

  type    = "CNAME"
  ttl     = 3600
  records = ["${var.server_name}-${var.active_server}.${var.domain_name}"]
}
