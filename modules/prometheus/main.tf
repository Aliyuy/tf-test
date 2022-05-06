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

resource "aws_iam_role" "prometheus" {
  name               = upper("${var.tier}_prometheus")
  assume_role_policy = data.aws_iam_policy_document.instance-assume-role-policy.json
  description        = "Allows ${upper(var.tier)} Prometheus servers to access required resources."
}

data "aws_iam_policy" "ec2_read_access" {
  arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

# Attach Prometheus role to EC2 Read Access policy
resource "aws_iam_role_policy_attachment" "prometheus" {
  role       = aws_iam_role.prometheus.name
  policy_arn = data.aws_iam_policy.ec2_read_access.arn

  lifecycle {
    prevent_destroy = true
  }
}

# Attach SSM-related policies to Prometheus role
resource "aws_iam_role_policy_attachment" "prometheus_attach_ssm_policy" {
  role       = aws_iam_role.prometheus.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "prometheus_attach_cloudwatch_agent_policy" {
  role       = aws_iam_role.prometheus.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_instance_profile" "prometheus" {
  name = aws_iam_role.prometheus.name
  role = aws_iam_role.prometheus.name
}

# Security group for prometheus servers

resource "aws_security_group" "prometheus" {
  name        = "${upper(var.tier)}-PROMETHEUS"
  description = "Prometheus ${upper(var.tier)} servers"
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
    from_port = 9090
    to_port   = 9090
    protocol  = "tcp"
    cidr_blocks = flatten([
      [data.aws_vpc.myvpc.cidr_block],
      [var.vpc_cidr_dev],
      [var.vpc_cidr_stg],
      [var.vpc_cidr_prd],
      var.vpn_cidrs
    ])
    description = "Prometheus from Internal"
  }

  ingress {
    from_port = 9093
    to_port   = 9093
    protocol  = "tcp"
    cidr_blocks = flatten([
      [data.aws_vpc.myvpc.cidr_block],
      [var.vpc_cidr_dev],
      [var.vpc_cidr_stg],
      [var.vpc_cidr_prd],
      var.vpn_cidrs
    ])
    description = "Alert Manager from Internal"
  }

  ingress {
    from_port = 9100
    to_port   = 9100
    protocol  = "tcp"
    cidr_blocks = flatten([
      [data.aws_vpc.myvpc.cidr_block],
      [var.vpc_cidr_dev],
      [var.vpc_cidr_stg],
      [var.vpc_cidr_prd],
      var.vpn_cidrs
    ])
    description = "Node Exporter from Internal"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${upper(var.tier)}-PROMETHEUS"
    Terraform = "true"
    tier      = var.tier
    cust      = var.customer
    service   = "prometheus_sg"
  }
}

# DNS Entries for prometheus servers
resource "aws_route53_record" "prometheus_a" {
  zone_id = var.zone_id
  name    = "${var.server_name}-a"
  type    = "A"
  ttl     = 3600
  records = [var.private_ip[0]]
}

resource "aws_route53_record" "prometheus_b" {
  zone_id = var.zone_id
  name    = "${var.server_name}-b"
  type    = "A"
  ttl     = 3600
  records = [var.private_ip[1]]
}

resource "aws_route53_record" "prometheus" {
  zone_id = var.zone_id
  name    = var.server_name

  type    = "CNAME"
  ttl     = 3600
  records = ["${var.server_name}-${var.active_server}.${var.domain_name}"]
}
