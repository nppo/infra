terraform {
  backend "s3" {
    key = "dev/rds/terraform.tfstate"
  }
}

provider "aws" {
  profile    = "surf-root"
  region     = "eu-central-1"
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = "edu-state"
    key    = "dev/vpc/terraform.tfstate"
    region = "eu-central-1"
  }
}

module "rds" {
  source = "../../modules/rds"

  db_name = "edushare"
  project = "surfpol"
  env = "dev"

  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnet_ids
}

output "security_group_access_id" {
  value = module.rds.security_group_access_id
  description = "The id of the security group that gives access to this database"
}

output "password" {
  value = module.rds.password
  description = "Password of the main user of the database"
}