resource "aws_iam_group" "superusers" {
  name = "superusers"
}

resource "aws_iam_policy" "superusers" {
  name        = "superuser"
  policy = file("${path.module}/superuser.json")
}

resource "aws_iam_group_policy_attachment" "superuser_attach" {
  group      = aws_iam_group.superusers.name
  policy_arn = aws_iam_policy.superusers.arn
}

locals {
  # pgp public key to encrypt new secrets
  pgp = file("${path.module}/jelmer.gpg.pubkey")
}

resource "aws_iam_user" "users" {
  for_each = var.users
  name = each.key

  # When destroying this user, destroy even if it has
  # non-Terraform-managed IAM access keys, login profile or MFA devices.
  force_destroy = true
}

resource "aws_iam_user_login_profile" "this" {
  for_each = aws_iam_user.users

  user = each.value.name
  pgp_key = local.pgp

  lifecycle {
    ignore_changes = [password_length, password_reset_required, pgp_key]
  }
}

resource "aws_iam_group_membership" "this" {
  for_each = transpose(var.users)

  name = "${each.key}-membership"
  users = each.value
  group = each.key
}

