provider "aws" {
  profile    = "pol-dev"
  region     = "eu-central-1"
}

module "remote-state" {
  source = "../../modules/remote-state"
  bucket_name = "edu-state"
}
