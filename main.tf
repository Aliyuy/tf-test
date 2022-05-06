locals {
  environment = "adm"
  prefix      = "${var.product_code}-${var.account_code}-adm-${var.aws_region_code}"

  rundeck_node_sg_ids = [
    data.terraform_remote_state.tf-infra-dev.outputs.rundeck_node_sg_id,
    data.terraform_remote_state.tf-infra-stg.outputs.rundeck_node_sg_id,
    data.terraform_remote_state.tf-infra-prd.outputs.rundeck_node_sg_id,
  ]
}

# Default EC2 keypair
resource "aws_key_pair" "deployer" {
  key_name   = "${var.customer}-${local.environment}-key"
  public_key = var.ssh_public_key
}

# Route 53 Internal Zone

resource "aws_route53_zone" "private" {
  name = var.domain_name

  vpc {
    vpc_id = var.vpc_id
  }

  tags = {
    Terraform   = "true"
    Environment = local.environment
    tier        = local.environment
    cust        = var.customer
    service     = "route_53_private_zone"
  }
}

resource "aws_security_group" "dns_resolver" {
  name        = "${upper(local.environment)}-Int-DNS-Resolver"
  description = "Route53 ${upper(local.environment)} internal DNS revolver services"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [var.private_cidr]
  }

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [var.private_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${upper(local.environment)}-Int-DNS-Resolver"
    Terraform = "true"
    tier      = local.environment
    cust      = var.customer
    service   = "route53_int_resolver_sg"
  }
}

resource "aws_route53_resolver_endpoint" "inbound" {
  name      = "${local.prefix}-inbound-resolver"
  direction = "INBOUND"

  security_group_ids = [
    aws_security_group.dns_resolver.id,
  ]

  ip_address {
    subnet_id = var.subnets_public[0]
    ip        = var.route53_resolver_ip[0]
  }

  ip_address {
    subnet_id = var.subnets_public[1]
    ip        = var.route53_resolver_ip[1]
  }

  tags = {
    Name      = "${local.prefix}-inbound-resolver"
    Terraform = "true"
    tier      = local.environment
    cust      = var.customer
    service   = "route53_inbound_resolver"
  }
}

resource "aws_route53_resolver_endpoint" "outbound" {
  name      = "${local.prefix}-outbound-resolver"
  direction = "OUTBOUND"

  security_group_ids = [
    aws_security_group.dns_resolver.id,
  ]

  ip_address {
    subnet_id = var.subnets_public[0]
    ip        = var.route53_outbound_resolver_ip[0]
  }

  ip_address {
    subnet_id = var.subnets_public[1]
    ip        = var.route53_outbound_resolver_ip[1]
  }

  tags = {
    Name      = "${local.prefix}-outbound-resolver"
    Terraform = "true"
    tier      = local.environment
    cust      = var.customer
    service   = "route53_outbound_resolver"
  }
}

resource "aws_route53_resolver_rule" "fwd_inbound" {
  domain_name          = var.ca_domain_name
  name                 = "Internal Resolver"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.outbound.id

  target_ip {
    ip = var.route53_resolver_ip[0]
  }

  target_ip {
    ip = var.route53_resolver_ip[1]
  }

  tags = {
    Terraform = "true"
    tier      = local.environment
    cust      = var.customer
    service   = "route53_inbound_resolver_rule"
  }
}

# Remove association with Admin (Ru) VPC due to possible timeouts (LSDO-33)
# resource "aws_route53_resolver_rule_association" "example" {
#   resolver_rule_id = aws_route53_resolver_rule.fwd_inbound.id
#   vpc_id           = var.vpc_id
# }

resource "aws_prdm_resource_share" "fwd_inbound" {
  name                      = "internal domain forwarder"
  allow_external_principals = true
}

resource "aws_prdm_resource_association" "fwd_inbound" {
  resource_arn       = aws_route53_resolver_rule.fwd_inbound.arn
  resource_share_arn = aws_prdm_resource_share.fwd_inbound.arn
}

resource "aws_prdm_principal_association" "fwd_inbound" {
  for_each = var.environment_aws_account_number

  principal          = each.value
  resource_share_arn = aws_prdm_resource_share.fwd_inbound.arn
}

# Private CA

resource "aws_acmpca_certificate_authority" "private_ca" {
  certificate_authority_configuration {
    key_algorithm     = "RSA_4096"
    signing_algorithm = "SHA512WITHRSA"

    subject {
      organization        = var.organization
      organizational_unit = var.organization_unit
      country             = var.organization_country
      state               = var.organization_state
      locality            = var.organization_locality
      common_name         = var.ca_domain_name
    }
  }

  type = "ROOT"

  enabled = false

  permanent_deletion_time_in_days = 7

  tags = {
    Terraform = "true"
    Workspace = local.environment
    Name      = "${upper(local.environment)} ${var.ca_domain_name} Private CA Root"
    tier      = local.environment
    cust      = var.customer
    service   = "private_ca_root"
  }
}

# Private Subordinate/Issuing CA (must sign with Ru ExampleCo.local Root CA)

resource "aws_acmpca_certificate_authority" "private_ca_issuing" {
  certificate_authority_configuration {
    key_algorithm     = "RSA_2048"
    signing_algorithm = "SHA256WITHRSA"

    subject {
      organization        = var.organization
      organizational_unit = var.organization_unit
      country             = var.organization_country
      state               = var.organization_state
      locality            = var.organization_locality
      common_name         = "${var.account_code}.${var.ca_domain_name}"
    }
  }

  type = "SUBORDINATE"

  enabled = true

  permanent_deletion_time_in_days = 7

  tags = {
    Terraform = "true"
    Workspace = local.environment
    Name      = "${upper(local.environment)} ${var.ca_domain_name} Private Issuing CA"
    tier      = local.environment
    cust      = var.customer
    service   = "private_ca_issuing"
  }
}

# VPC peering configurations

# Dev - ex-dev
data "aws_caller_identity" "dev" {
  provider = aws.og
}

resource "aws_vpc_peering_connection" "dev" {
  vpc_id        = var.vpc_id
  peer_vpc_id   = var.vpc_id_dev
  peer_owner_id = data.aws_caller_identity.dev.account_id
  peer_region   = var.aws_region
  auto_accept   = false

  tags = {
    Side = "Requester"
  }
}

resource "aws_vpc_peering_connection_accepter" "dev" {
  provider                  = aws.og
  vpc_peering_connection_id = aws_vpc_peering_connection.dev.id
  auto_accept               = true

  tags = {
    Side = "Accepter"
  }
}

# Stg - ex-stg
data "aws_caller_identity" "stg" {
  provider = aws.rh
}

resource "aws_vpc_peering_connection" "stg" {
  vpc_id        = var.vpc_id
  peer_vpc_id   = var.vpc_id_stg
  peer_owner_id = data.aws_caller_identity.stg.account_id
  peer_region   = var.aws_region
  auto_accept   = false

  tags = {
    Side = "Requester"
  }
}

resource "aws_vpc_peering_connection_accepter" "stg" {
  provider                  = aws.rh
  vpc_peering_connection_id = aws_vpc_peering_connection.stg.id
  auto_accept               = true

  tags = {
    Side = "Accepter"
  }
}

# Prd - ex-prd
data "aws_caller_identity" "prd" {
  provider = aws.ra
}

resource "aws_vpc_peering_connection" "prd" {
  vpc_id        = var.vpc_id
  peer_vpc_id   = var.vpc_id_prd
  peer_owner_id = data.aws_caller_identity.prd.account_id
  peer_region   = var.aws_region
  auto_accept   = false

  tags = {
    Side = "Requester"
  }
}

resource "aws_vpc_peering_connection_accepter" "prd" {
  provider                  = aws.ra
  vpc_peering_connection_id = aws_vpc_peering_connection.prd.id
  auto_accept               = true

  tags = {
    Side = "Accepter"
  }
}

# S3 buckets and access policies
module "storage" {
  source = "./modules/storage"

  label             = local.prefix
  s3_logging_bucket = var.s3_logging_bucket
}

module "s3_backups_access" {
  source = "./modules/storage/access"

  bucket_name = "${local.prefix}-backups"
}

module "s3_deploy_access" {
  source = "./modules/storage/access"

  bucket_name = "${local.prefix}-deploy"
}

module "s3_pypi_access" {
  source = "./modules/storage/access"

  bucket_name = "${local.prefix}-pypi"
}


# IAM roles to manage application components access to S3 and other items

module "roles" {
  source = "./modules/roles"

  domain_name                  = var.domain_name
  deploy_fullaccess_policy_arn = module.s3_deploy_access.fullaccess_policy_arn
}

# Add IAM Role, policies, security group and target group definitions for each app as required

# Jenkins
module "jenkins" {
  source = "./modules/jenkins"

  aws_account_number = var.aws_account_number
  backups_policy_arn = module.s3_backups_access.writeaccess_policy_arn
  customer           = var.customer
  domain_name        = var.domain_name
  private_ca_arn     = data.aws_acmpca_certificate_authority.private_ca_issuing.arn
  private_ip         = var.jenkins_private_ip
  server_name        = "jenkins"
  subnets            = var.subnets_public
  tier               = local.environment
  vpc_id             = var.vpc_id
  vpn_cidrs          = var.vpn_cidrs
  vpn_cidr_mgmt      = var.vpn_cidr_upper
  zone_id            = aws_route53_zone.private.zone_id
}

# Prometheus
module "prometheus" {
  source = "./modules/prometheus"

  aws_account_number = var.aws_account_number
  customer           = var.customer
  domain_name        = var.domain_name
  private_ip         = var.prometheus_private_ip
  server_name        = "prometheus"
  subnets            = var.subnets_public
  tier               = local.environment
  vpc_id             = var.vpc_id
  vpc_cidr_dev       = var.vpc_cidr_dev
  vpc_cidr_stg       = var.vpc_cidr_stg
  vpc_cidr_prd       = var.vpc_cidr_prd
  vpn_cidrs          = var.vpn_cidrs
  vpn_cidr_mgmt      = var.vpn_cidr_upper
  zone_id            = aws_route53_zone.private.zone_id
}

# PyPI
module "pypi" {
  source = "./modules/pypi"

  aws_account_number = var.aws_account_number
  bucket_policy_arn  = module.s3_pypi_access.fullaccess_policy_arn
  customer           = var.customer
  domain_name        = var.domain_name
  private_ip         = var.pypi_private_ip
  server_name        = "pypi"
  subnets            = var.subnets_public
  tier               = local.environment
  vpc_id             = var.vpc_id
  vpc_cidr_dev       = var.vpc_cidr_dev
  vpc_cidr_stg       = var.vpc_cidr_stg
  vpc_cidr_prd       = var.vpc_cidr_prd
  vpn_cidrs          = var.vpn_cidrs
  vpn_cidr_mgmt      = var.vpn_cidr_upper
  zone_id            = aws_route53_zone.private.zone_id
}

# Rundeck
module "rundeck" {
  source = "./modules/rundeck"

  aws_account_number = var.aws_account_number
  backups_policy_arn = module.s3_backups_access.writeaccess_policy_arn
  customer           = var.customer
  deploy_policy_arn  = module.s3_deploy_access.writeaccess_policy_arn
  domain_name        = var.domain_name
  private_ca_arn     = aws_acmpca_certificate_authority.private_ca_issuing.arn
  private_ip         = var.rundeck_private_ip
  server_name        = "rundeck"
  subnets            = var.subnets_public
  tier               = local.environment
  vpc_id             = var.vpc_id
  vpn_cidrs          = var.vpn_cidrs
  vpn_cidr_mgmt      = var.vpn_cidr_upper
  zone_id            = aws_route53_zone.private.zone_id

  rundeck_node_sg_ids = local.rundeck_node_sg_ids
}

# Sensu
module "sensu" {
  source = "./modules/sensu"

  aws_account_number = var.aws_account_number
  backups_policy_arn = module.s3_backups_access.writeaccess_policy_arn
  customer           = var.customer
  domain_name        = var.domain_name
  private_ca_arn     = aws_acmpca_certificate_authority.private_ca_issuing.arn
  private_ip         = var.sensu_private_ip
  server_name        = "sensu-ru"
  subnets            = var.subnets_public
  tier               = local.environment
  vpc_id             = var.vpc_id
  vpc_cidr_dev       = var.vpc_cidr_dev
  vpc_cidr_stg       = var.vpc_cidr_stg
  vpc_cidr_prd       = var.vpc_cidr_prd
  vpn_cidrs          = var.vpn_cidrs
  vpn_cidr_mgmt      = var.vpn_cidr_upper
  zone_id            = aws_route53_zone.private.zone_id
}
