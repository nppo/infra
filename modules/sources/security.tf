##################################################
# Credentials
##################################################

resource "aws_secretsmanager_secret" "hva_credentials" {
  name = "credentials/hva"
  description = "HvA Pure API key"
}

resource "aws_secretsmanager_secret_version" "hva_credentials_key" {
  secret_id     = aws_secretsmanager_secret.hva_credentials.id
  secret_string = jsonencode({ api_key = "" })
}

resource "aws_secretsmanager_secret" "sharekit_credentials" {
  name = "credentials/sharekit"
  description = "Sharekit JSON API credentials"
}

resource "aws_secretsmanager_secret_version" "sharekit_credentials_key" {
  secret_id     = aws_secretsmanager_secret.sharekit_credentials.id
  secret_string = jsonencode({ api_key = "" })
}

resource "aws_secretsmanager_secret" "hanze_credentials" {
  name = "credentials/hanze"
  description = "Hanze Azure API credentials"
}

resource "aws_secretsmanager_secret_version" "hanze_credentials_key" {
  secret_id     = aws_secretsmanager_secret.hanze_credentials.id
  secret_string = jsonencode({ api_key = "" })
}

resource "aws_secretsmanager_secret" "buas_credentials" {
  name = "credentials/buas"
  description = "BUAS Pure API credentials"
}

resource "aws_secretsmanager_secret_version" "buas_credentials_key" {
  secret_id     = aws_secretsmanager_secret.buas_credentials.id
  secret_string = jsonencode({ api_key = "" })
}

resource "aws_secretsmanager_secret" "sia_credentials" {
  name = "credentials/sia"
  description = "SIA API credentials"
}

resource "aws_secretsmanager_secret_version" "sia_credentials_key" {
  secret_id     = aws_secretsmanager_secret.sia_credentials.id
  secret_string = jsonencode({ api_key = "" })
}

##################################################
# AWS policies that manage access rights
##################################################

data "template_file" "external_credentials_policy" {
  template = file("${path.module}/external-credentials-policy.json.tpl")
  vars = {
    sharekit_credentials_arn = aws_secretsmanager_secret.sharekit_credentials.arn
    hanze_credentials_arn = aws_secretsmanager_secret.hanze_credentials.arn
    hva_credentials_arn = aws_secretsmanager_secret.hva_credentials.arn
    buas_credentials_arn = aws_secretsmanager_secret.buas_credentials.arn
    sia_credentials_arn = aws_secretsmanager_secret.sia_credentials.arn
  }
}

resource "aws_iam_policy" "external_credentials_policy" {
  name        = "ecsExternalCredentialsPolicy"
  description = "Policy for using credentials from external sources"
  policy = data.template_file.external_credentials_policy.rendered
}

resource "aws_iam_role_policy_attachment" "harvester" {
  role = var.harvester_task_role_name
  policy_arn = aws_iam_policy.external_credentials_policy.arn
}

resource "aws_iam_role_policy_attachment" "middleware" {
  role = var.middleware_task_role_name
  policy_arn = aws_iam_policy.external_credentials_policy.arn
}

resource "aws_iam_role_policy_attachment" "superuser" {
  role = var.superuser_task_role_name
  policy_arn = aws_iam_policy.external_credentials_policy.arn
}
