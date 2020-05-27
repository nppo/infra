locals {
  project = "surfpol"
  env = "prod"
}

terraform {
  backend "s3" {
    key = "prod/terraform.tfstate"
    region = "eu-central-1"
    bucket = "pol-prod-state"
    profile = "pol-prod"
  }
}

provider "aws" {
  profile    = "pol-prod"
  region     = "eu-central-1"
}

module "user-access" {
  source = "../modules/user-access"

  users = {"fako.berkers@surfnet.nl" = ["superusers"]
           "kruys@zilverline.com" = ["superusers"]
           "rhartog@zilverline.com" = ["superusers"]}
}
