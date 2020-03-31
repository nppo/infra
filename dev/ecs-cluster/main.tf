terraform {
  backend "s3" {
    key = "dev/ecs-cluster/terraform.tfstate"
  }
}

provider "aws" {
  profile    = "surf"
  region     = "eu-central-1"
}

module "ecs-cluster" {
  source = "../../modules/ecs-cluster"

  project = "surfpol"
  env = "dev"
}