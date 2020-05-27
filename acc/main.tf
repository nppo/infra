locals {
  project = "surfpol"
  env = "acc"
}

terraform {
  backend "s3" {
    key = "acc/terraform.tfstate"
    region = "eu-central-1"
    bucket = "pol-acc-state"
    profile = "pol-acc"
  }
}

provider "aws" {
  profile    = "pol-acc"
  region     = "eu-central-1"
}

module "user-access" {
  source = "../modules/user-access"

  users = {"fako.berkers@surfnet.nl" = ["superusers"]
           "kruys@zilverline.com" = ["superusers"]
           "rhartog@zilverline.com" = ["superusers"]}
}
