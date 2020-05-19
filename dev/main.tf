terraform {
  backend "s3" {
    key = "dev/terraform.tfstate"
    region = "eu-central-1"
    bucket = "edu-state"
    profile = "surf-root"
  }
}

provider "aws" {
  profile    = "surf-root"
  region     = "eu-central-1"
}

module "vpc" {
  source = "../modules/vpc"

  project = "surfpol"
  env = "dev"
  cidr = "10.0.0.0/16"

  azs = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
}

output "vpc_id" {
  value = module.vpc.vpc_id
  description = "The id for this VPC"
}

output "private_subnet_ids" {
  value =  module.vpc.private_subnet_ids
  description = "The subnet ids for the private subnets"
}
