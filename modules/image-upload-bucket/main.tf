locals {
  common_tags = {
    Project = var.project
    ProvisionedBy = "Terraform"
  }
}

resource "aws_s3_bucket" "image-uploads" {
  bucket = var.name
  acl = "public-read"

  tags = local.common_tags
}
