locals {
  project = "surfpol"
  env = "dev"
  eduvpn_ips = ["145.90.230.0/23", "145.101.60.0/23", "2001:610:450:50::/60", "2001:610:3:2150::/60"]
  domain_name = "dev.surfedushare.nl"
}

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

  project = local.project
  env = local.env
  cidr = "10.0.0.0/16"

  azs = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
}

module "bastion" {
  source = "../modules/bastion"

  project = local.project
  env = local.env

  vpc_id = module.vpc.vpc_id
  subnet_id = module.vpc.private_subnet_ids[0]
}

module "rds" {
  source = "../modules/rds"

  db_name = "edushare"
  project = local.project
  env = local.env

  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
}

module "ecs-cluster" {
  source = "../modules/ecs-cluster"

  project = local.project
  env = local.env
}

module "load-balancer" {
  source = "../modules/load-balancer"

  project = local.project
  env = local.env

  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnet_ids
  eduvpn_ips = local.eduvpn_ips
  domain_name = local.domain_name
  default_security_group_id = module.vpc.default_security_group_id
}

module "log_group" {
  source = "../modules/log-group"

  project = local.project
  env = local.env
  retention_in_days = 14
}
