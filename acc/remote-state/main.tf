provider "aws" {
  profile    = "pol-acc"
  region     = "eu-central-1"
}

module "remote-state" {
  source = "../../modules/remote-state"
  bucket_name = "pol-acc-state"
}
