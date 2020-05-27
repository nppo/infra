provider "aws" {
  profile    = "pol-prod"
  region     = "eu-central-1"
}

module "remote-state" {
  source = "../../modules/remote-state"
  bucket_name = "pol-prod-state"
}

