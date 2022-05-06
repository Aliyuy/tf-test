provider "aws" {
  region              = var.aws_region
  allowed_account_ids = ["975163932648"]

  assume_role {
    role_arn     = "arn:aws:iam::975163932648:role/TerraformAssumedIamRole"
    session_name = "terraform"
  }
}

provider "aws" {
  alias               = "dev"
  region              = var.aws_region
  allowed_account_ids = ["790668890258"]

  assume_role {
    role_arn     = "arn:aws:iam::790668890258:role/TerraformAssumedIamRole"
    session_name = "terraform_dev"
  }
}

provider "aws" {
  alias               = "stg"
  region              = var.aws_region
  allowed_account_ids = ["788051111186"]

  assume_role {
    role_arn     = "arn:aws:iam::788051111186:role/TerraformAssumedIamRole"
    session_name = "terraform_stg"
  }
}

provider "aws" {
  alias               = "prd"
  region              = var.aws_region
  allowed_account_ids = ["537777728142"]

  assume_role {
    role_arn     = "arn:aws:iam::537777728142:role/TerraformAssumedIamRole"
    session_name = "terraform_prd"
  }
}

data "terraform_remote_state" "tf-admin" {
  backend = "s3"

  config = {
    bucket   = "ex-adm-adm-ue1-terraform-state"
    key      = "tf-admin/terraform.tfstate"
    region   = "us-east-1"
    role_arn = "arn:aws:iam::975163932648:role/TerraformAssumedIamRole"
  }
}

data "terraform_remote_state" "tf-infra-dev" {
  backend = "s3"

  config = {
    bucket   = "ex-adm-adm-ue1-terraform-state"
    key      = "tf-infra/terraform.tfstate"
    region   = "us-east-1"
    role_arn = "arn:aws:iam::975163932648:role/TerraformAssumedIamRole"
  }

  workspace = "dev"
}

data "terraform_remote_state" "tf-infra-stg" {
  backend = "s3"

  config = {
    bucket   = "ex-adm-adm-ue1-terraform-state"
    key      = "tf-infra/terraform.tfstate"
    region   = "us-east-1"
    role_arn = "arn:aws:iam::975163932648:role/TerraformAssumedIamRole"
  }

  workspace = "stg"
}

data "terraform_remote_state" "tf-infra-prd" {
  backend = "s3"

  config = {
    bucket   = "ex-adm-adm-ue1-terraform-state"
    key      = "tf-infra/terraform.tfstate"
    region   = "us-east-1"
    role_arn = "arn:aws:iam::975163932648:role/TerraformAssumedIamRole"
  }

  workspace = "prd"
}
