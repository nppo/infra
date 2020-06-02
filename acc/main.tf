locals {
  project = "surfpol"
  env = "acc"
  ipv4_eduvpn_ips = ["145.90.230.0/23", "145.101.60.0/23"]
  ipv6_eduvpn_ips = ["2001:610:450:50::/60", "2001:610:3:2150::/60"]
}

terraform {
  required_version = "~> 0.12"
  backend "s3" {
    key = "acc/terraform.tfstate"
    region = "eu-central-1"
    bucket = "pol-acc-state"
    profile = "pol-acc"
  }
}

provider "aws" {
  version    = "~> 2.63"
  profile    = "pol-acc"
  region     = "eu-central-1"
}

resource "aws_iam_account_alias" "alias" {
  account_alias = "surfpol-acc"
}

module "user-access" {
  source = "../modules/user-access"

  users = {"fako.berkers@surfnet.nl" = ["superusers"]
           "kruys@zilverline.com" = ["superusers"]
           "rhartog@zilverline.com" = ["superusers"]}
}

module "vpc" {
  source = "../modules/vpc"

  project = local.project
  env = local.env
  cidr = "10.0.0.0/16"

  azs = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  ipv4_eduvpn_ips = local.ipv4_eduvpn_ips
  ipv6_eduvpn_ips = local.ipv6_eduvpn_ips
}