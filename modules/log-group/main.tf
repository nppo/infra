resource "aws_cloudwatch_log_group" "this" {
  name = "${var.project}-${var.env}"
  retention_in_days = var.retention_in_days

  tags = {
    Name = "${var.project}-${var.env}"
    Project = var.project
    Environment = var.env
    ProvisionedBy = "Terraform"
  }
}

data "template_file" "this" {
  template = file("${path.module}/policy.json.tpl")
  vars = {
    log_group_name = aws_cloudwatch_log_group.this.name
  }
}

resource "aws_iam_policy" "this" {
  name        = "${var.project}-${var.env}-logs-manage"
  description = "Policy for managing the ${var.project}-${var.env} logs"
  policy = data.template_file.this.rendered
}
