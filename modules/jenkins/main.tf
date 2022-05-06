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

resource "aws_iam_role" "jenkins" {
  name               = upper("${var.tier}_JENKINS")
  assume_role_policy = data.aws_iam_policy_document.instance-assume-role-policy.json
  description        = "Allows ${upper(var.tier)} Jenkins servers to access/provision required resources."
}

data "aws_iam_policy" "ec2_deploy_access" {
  arn = "arn:aws:iam::${var.aws_account_number}:policy/JenkinsEC2Policy"
}

# Attach Terraform IAM assumed role to Jenkins policy
resource "aws_iam_role_policy_attachment" "jenkins" {
  role       = aws_iam_role.jenkins.name
  policy_arn = data.aws_iam_policy.ec2_deploy_access.arn

  lifecycle {
    prevent_destroy = true
  }
}

# Attach S3 backups policy to Jenkins role
resource "aws_iam_role_policy_attachment" "jenkins_attach_backups_policy" {
  role       = aws_iam_role.jenkins.name
  policy_arn = var.backups_policy_arn

  lifecycle {
    prevent_destroy = true
  }
}

# Attach SSM-related policies to Jenkins role
resource "aws_iam_role_policy_attachment" "jenkins_attach_ssm_policy" {
  role       = aws_iam_role.jenkins.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "jenkins_attach_cloudwatch_agent_policy" {
  role       = aws_iam_role.jenkins.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_instance_profile" "jenkins" {
  name = aws_iam_role.jenkins.name
  role = aws_iam_role.jenkins.name
}

# Security group for Jenkins servers

resource "aws_security_group" "jenkins" {
  name        = "${upper(var.tier)}-Jenkins"
  description = "jenkins ${upper(var.tier)} servers"
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
    # TLS (Jenkins via Nginx Reverse Proxy)
    from_port = 443
    to_port   = 443
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
    Name      = "${upper(var.tier)}-Jenkins"
    Terraform = "true"
    tier      = var.tier
    cust      = var.customer
    service   = "jenkins_sg"
  }
}

# Security group for Jenkins workers

resource "aws_security_group" "jenkins_worker" {
  name        = "${upper(var.tier)}-Jenkins-Worker"
  description = "jenkins ${upper(var.tier)} worker"
  vpc_id      = var.vpc_id

  ingress {
    # SSH
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = flatten([
      [data.aws_vpc.myvpc.cidr_block],
      var.vpn_cidr_mgmt
    ])

    security_groups = [
      aws_security_group.jenkins.id,
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${upper(var.tier)}-Jenkins-Worker"
    Terraform = "true"
    tier      = var.tier
    cust      = var.customer
    service   = "jenkins_worker_sg"
  }
}

# DNS Entries for Jenkins servers
resource "aws_route53_record" "jenkins_a" {
  zone_id = var.zone_id
  name    = "${var.server_name}-a"
  type    = "A"
  ttl     = 3600
  records = [var.private_ip[0]]
}

resource "aws_route53_record" "jenkins_b" {
  zone_id = var.zone_id
  name    = "${var.server_name}-b"
  type    = "A"
  ttl     = 3600
  records = [var.private_ip[1]]
}

resource "aws_route53_record" "jenkins" {
  zone_id = var.zone_id
  name    = var.server_name

  type    = "CNAME"
  ttl     = 3600
  records = ["${var.server_name}-${var.active_server}.${var.domain_name}"]
}

# Private certificate for Jenkins server
resource "aws_acm_certificate" "jenkins" {
  domain_name               = "jenkins.${var.domain_name}"
  certificate_authority_arn = var.private_ca_arn

  subject_alternative_names = [
    "${var.server_name}-${var.active_server}.${var.domain_name}",
  ]

  tags = {
    Name      = "${upper(var.tier)}-Jenkins certificate"
    Terraform = "true"
    tier      = var.tier
    cust      = var.customer
    service   = "jenkins_cert"
  }
}
