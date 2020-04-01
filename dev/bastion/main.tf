terraform {
  backend "s3" {
    key = "dev/bastion/terraform.tfstate"
  }
}

provider "aws" {
  profile    = "surf"
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

module "bastion" {
  source = "../../modules/bastion"

  project = "surfpol"
  env = "dev"

  subnet_id = data.terraform_remote_state.vpc.outputs.private_subnet_ids[0]
}

output "id" {
  value = module.bastion.id
  description = "The id for this bastion instance"
}