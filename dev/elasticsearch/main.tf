terraform {
  backend "s3" {
    key = "dev/elasticsearch/terraform.tfstate"
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

module "log_group" {
  source = "../../modules/log-group"

  name = "elasticsearch"
  project = "surfpol"
  env = "dev"
  retention_in_days = 14
}

module "elasticsearch" {
  source = "../../modules/elasticsearch"

  domain_name = "main"
  project = "surfpol"
  env = "dev"
  elasticsearch_version = "7.4"
  instance_type = "t2.medium.elasticsearch"
  instance_count = 1
  instance_volume_size = 10
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnet_ids
  log_group_name = module.log_group.name
  log_group_arn = module.log_group.arn
}