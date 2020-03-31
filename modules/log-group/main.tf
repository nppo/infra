resource "aws_cloudwatch_log_group" "this" {
  name = "${var.project}-${var.env}-${var.name}"
  retention_in_days = var.retention_in_days

  tags = {
    Name = "${var.project}-${var.env}-${var.name}"
    Project = var.project
    Environment = var.env
    ProvisionedBy = "Terraform"
  }
}
