terraform {
  backend "s3" {
    key = "dev/ecs-cluster/terraform.tfstate"
  }
}

provider "aws" {
  profile    = "surf-root"
  region     = "eu-central-1"
}

module "ecs-cluster" {
  source = "../../modules/ecs-cluster"

  project = "surfpol"
  env = "dev"
}

output "policy_arn" {
  value = module.ecs-cluster.policy_arn
  description = "The Policy arn for managing this cluster"
}