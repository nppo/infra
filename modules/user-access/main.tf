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
  pgp_key = "keybase:fako.berkers@surf.nl"

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

# Based on: https://www.solarwindsmsp.com/blog/nist-password-standards2
resource "aws_iam_account_password_policy" "this" {
  hard_expiry                    = false
  minimum_password_length        = 14
  require_lowercase_characters   = false
  require_numbers                = false
  require_uppercase_characters   = false
  require_symbols                = false
  allow_users_to_change_password = true
  password_reuse_prevention      = 2
}
