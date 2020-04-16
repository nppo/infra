terraform {
  backend "s3" {
    key = "dev/log-group/terraform.tfstate"
  }
}

provider "aws" {
  profile    = "surf-root"
  region     = "eu-central-1"
}

module "log_group" {
  source = "../../modules/log-group"

  project = "surfpol"
  env = "dev"
  retention_in_days = 14
}

output "policy_arn" {
  value = module.log_group.policy_arn
  description = "The Policy arn for managing this log-group"
}