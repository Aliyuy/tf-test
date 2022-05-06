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

resource "aws_iam_role" "sensu" {
  name               = upper("${var.tier}_SENSU")
  assume_role_policy = data.aws_iam_policy_document.instance-assume-role-policy.json
  description        = "Allows ${upper(var.tier)} Sensu servers to access/provision required resources."
}

# Attach S3 backups policy to Sensu role
resource "aws_iam_role_policy_attachment" "sensu_attach_backups_policy" {
  role       = aws_iam_role.sensu.name
  policy_arn = var.backups_policy_arn

  lifecycle {
    prevent_destroy = true
  }
}

# Attach CloudWatch read-only policy to Sensu role
resource "aws_iam_role_policy_attachment" "sensu_attach_cloudwatch_policy" {
  role       = aws_iam_role.sensu.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"

  lifecycle {
    prevent_destroy = true
  }
}

# Allow the Sensu role to read CloudWatch in Og (dev) account
resource "aws_iam_role_policy" "cloudwatch_dev_read_policy" {
  name = "Allow-Assume-CloudWatch-Role-in-Og"
  role = aws_iam_role.sensu.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Resource": "arn:aws:iam::790668890258:role/CloudWatchAssumedIamRole"
  }
}
EOF
}

# Allow the Sensu role to read CloudWatch in Rh (stg) account
resource "aws_iam_role_policy" "cloudwatch_stg_read_policy" {
  name = "Allow-Assume-CloudWatch-Role-in-Rh"
  role = aws_iam_role.sensu.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Resource": "arn:aws:iam::788051111186:role/CloudWatchAssumedIamRole"
  }
}
EOF
}

# Allow the Sensu role to read CloudWatch in Ra (prd) account
resource "aws_iam_role_policy" "cloudwatch_prd_read_policy" {
  name = "Allow-Assume-CloudWatch-Role-in-Ra"
  role = aws_iam_role.sensu.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Resource": "arn:aws:iam::537777728142:role/CloudWatchAssumedIamRole"
  }
}
EOF
}

# Attach SSM-related policies to Sensu role
resource "aws_iam_role_policy_attachment" "sensu_attach_ssm_policy" {
  role       = aws_iam_role.sensu.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "sensu_attach_cloudwatch_agent_policy" {
  role       = aws_iam_role.sensu.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_instance_profile" "sensu" {
  name = aws_iam_role.sensu.name
  role = aws_iam_role.sensu.name
}

# Security group for Sensu servers

resource "aws_security_group" "sensu" {
  name        = "${upper(var.tier)}-Sensu"
  description = "sensu ${upper(var.tier)} servers"
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
    # Graphite (Graphite data collection dashboard)
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = flatten([
      [data.aws_vpc.myvpc.cidr_block],
      [var.vpc_cidr_dev],
      [var.vpc_cidr_stg],
      [var.vpc_cidr_prd],
      var.vpn_cidrs
    ])
  }

  ingress {
    # TLS (Sensu via Nginx Reverse Proxy)
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = flatten([
      [data.aws_vpc.myvpc.cidr_block],
      var.vpn_cidrs
    ])
  }

  ingress {
    # Graphite (Graphite data collection)
    from_port = 2003
    to_port   = 2003
    protocol  = "tcp"
    cidr_blocks = flatten([
      [data.aws_vpc.myvpc.cidr_block],
      [var.vpc_cidr_dev],
      [var.vpc_cidr_stg],
      [var.vpc_cidr_prd],
      var.vpn_cidrs
    ])
  }

  ingress {
    # Uchiwa (Sensu Uchiwa dashboard)
    from_port = 3000
    to_port   = 3000
    protocol  = "tcp"
    cidr_blocks = flatten([
      [data.aws_vpc.myvpc.cidr_block],
      var.vpn_cidrs
    ])
  }

  ingress {
    # Uchiwa (Uchiwa API data)
    from_port = 4567
    to_port   = 4567
    protocol  = "tcp"
    cidr_blocks = flatten([
      [data.aws_vpc.myvpc.cidr_block],
      [var.vpc_cidr_dev],
      [var.vpc_cidr_stg],
      [var.vpc_cidr_prd],
      var.vpn_cidrs
    ])
  }

  ingress {
    # RabbitMQ (Sensu vhost)
    from_port = 5671
    to_port   = 5671
    protocol  = "tcp"
    cidr_blocks = flatten([
      [data.aws_vpc.myvpc.cidr_block],
      [var.vpc_cidr_dev],
      [var.vpc_cidr_stg],
      [var.vpc_cidr_prd],
      var.vpn_cidrs
    ])
  }

  ingress {
    # RabbitMQ (RabbitMQ)
    from_port = 5672
    to_port   = 5672
    protocol  = "tcp"
    cidr_blocks = flatten([
      [data.aws_vpc.myvpc.cidr_block],
      [var.vpc_cidr_dev],
      [var.vpc_cidr_stg],
      [var.vpc_cidr_prd],
      var.vpn_cidrs
    ])
  }

  ingress {
    # RabbitMQ (RabbitMQ management UI)
    from_port = 15672
    to_port   = 15672
    protocol  = "tcp"
    cidr_blocks = flatten([
      [data.aws_vpc.myvpc.cidr_block],
      var.vpn_cidrs
    ])
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${upper(var.tier)}-Sensu"
    Terraform = "true"
    tier      = var.tier
    cust      = var.customer
    service   = "sensu_sg"
  }
}

# DNS Entries for Sensu servers
resource "aws_route53_record" "sensu_a" {
  zone_id = var.zone_id
  name    = "${var.server_name}-a"
  type    = "A"
  ttl     = 3600
  records = [var.private_ip[0]]
}

resource "aws_route53_record" "sensu_b" {
  zone_id = var.zone_id
  name    = "${var.server_name}-b"
  type    = "A"
  ttl     = 3600
  records = [var.private_ip[1]]
}

resource "aws_route53_record" "sensu" {
  zone_id = var.zone_id
  name    = var.server_name

  type    = "CNAME"
  ttl     = 3600
  records = ["${var.server_name}-${var.active_server}.${var.domain_name}"]
}

# Private certificate for Sensu server
resource "aws_acm_certificate" "sensu" {
  domain_name               = "sensu.${var.domain_name}"
  certificate_authority_arn = var.private_ca_arn

  subject_alternative_names = [
    "${var.server_name}-${var.active_server}.${var.domain_name}",
  ]

  tags = {
    Name      = "${upper(var.tier)}-Sensucertificate"
    Terraform = "true"
    tier      = var.tier
    cust      = var.customer
    service   = "sensu_cert"
  }
}
