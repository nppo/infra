terraform {
  backend "s3" {
    key = "global/iam/terraform.tfstate"
  }
}

provider "aws" {
  profile    = "surf-root"
  region     = "eu-central-1"
}

locals {
  # pgp public key to encrypt new secrets
  pgp = file("${path.module}/jelmer.gpg.pubkey")

  # groups
  groups = ["developers"]

  # mapping of users to groups
  users = {"jelmer" = ["developers"]
           "fako" = ["developers"]}
}

data "terraform_remote_state" "dev_ecs" {
  backend = "s3"

  config = {
    bucket = "edu-state"
    key    = "dev/ecs-cluster/terraform.tfstate"
    region = "eu-central-1"
  }
}

data "terraform_remote_state" "dev_logs" {
  backend = "s3"

  config = {
    bucket = "edu-state"
    key    = "dev/log-group/terraform.tfstate"
    region = "eu-central-1"
  }
}

# == Account alias ==
resource "aws_iam_account_alias" "this" {
  account_alias = "surf-edu"
}

# == Users ==

resource "aws_iam_user" "this" {
  for_each = local.users

  name = each.key

  # When destroying this user, destroy even if it has
  # non-Terraform-managed IAM access keys, login profile or MFA devices.
  force_destroy = true
}

resource "aws_iam_user_login_profile" "this" {
  for_each = aws_iam_user.this

  user = each.value.name
  pgp_key = local.pgp
}

resource "aws_iam_access_key" "this" {
  for_each = aws_iam_user.this

  user    = each.value.name
  pgp_key = local.pgp
}

# == Groups ==

resource "aws_iam_group" "this" {
  for_each = toset(local.groups)

  name = each.value
}

resource "aws_iam_group_membership" "this" {
  for_each = transpose(local.users)

  name = "${each.key}-membership"
  users = each.value
  group = aws_iam_group.this[each.key].name
}

# == Policies ==

resource "aws_iam_policy" "base" {
  name        = "base"
  description = "Base policy for developer access"
  policy = file("${path.module}/base.json")
}

# == Policy attachments ==

resource "aws_iam_group_policy_attachment" "base_attach" {
  group      = aws_iam_group.this["developers"].name
  policy_arn = aws_iam_policy.base.arn
}

resource "aws_iam_group_policy_attachment" "ecs_dev_attach" {
  group      = aws_iam_group.this["developers"].name
  policy_arn = data.terraform_remote_state.dev_ecs.outputs.policy_arn
}

resource "aws_iam_group_policy_attachment" "log_dev_attach" {
  group      = aws_iam_group.this["developers"].name
  policy_arn = data.terraform_remote_state.dev_logs.outputs.policy_arn
}
