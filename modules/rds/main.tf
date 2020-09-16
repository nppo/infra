locals {
  common_tags = {
    Project = var.project
    Environment = var.env
    ProvisionedBy = "Terraform"
  }
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.project}-${var.env}-${var.db_name}"
  subnet_ids = var.subnet_ids

  tags = merge(local.common_tags, {Name = "${var.project}-${var.db_name}"})
}

resource "aws_security_group" "access" {
  name        = "${var.project}-${var.env}-${var.db_name}-access"
  description = "Allows access to the ${var.project}-${var.env}-${var.db_name} database"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {Name = "${var.project}-${var.db_name}-access"})
}

resource "aws_security_group" "db" {
  name = "${var.project}-${var.env}-${var.db_name}-db"
  description = "Protects the ${var.project}-${var.env}-${var.db_name} database"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_security_group.access.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [aws_security_group.access.id]
  }

  tags = merge(local.common_tags, {Name = "${var.project}-${var.db_name}-db"})
}

resource "random_password" "password" {
  length = 32
  special = false
}

resource "aws_secretsmanager_secret" "rds_credentials" {
  name = "search-portal/postgres"
  description = "Root user credentials for the RDS Postgres instance"
}

resource "aws_secretsmanager_secret_version" "postgres_password" {
  secret_id     = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({ password = random_password.password.result })
}

resource "aws_db_parameter_group" "postgres12" {
  name   = "${var.project}-${var.db_name}"
  family = "postgres12"

  parameter {
    name  = "timezone"
    value = "Europe/Amsterdam"
  }

  tags = merge(local.common_tags, {Name = "${var.project}-${var.db_name}"})
}

resource "aws_db_instance" "surfpol" {
  identifier               = "${var.project}-${var.db_name}"
  db_subnet_group_name     = aws_db_subnet_group.this.name
  multi_az                 = false
  vpc_security_group_ids   = [aws_security_group.db.id]

  allocated_storage        = 20
  max_allocated_storage    = 1000
  storage_type             = "gp2"
  engine                   = "postgres"
  engine_version           = "12.2"
  instance_class           = "db.t2.micro"
  name                     = var.db_name
  #storage_encrypted        = true

  parameter_group_name     = aws_db_parameter_group.postgres12.name

  username                 = "postgres"
  password                 = jsondecode(aws_secretsmanager_secret_version.postgres_password.secret_string)["password"]

  final_snapshot_identifier = "${var.project}-${var.db_name}-final"
  backup_retention_period  = 35
  backup_window            = "02:00-03:00"
  delete_automated_backups = true

  #deletion_protection      = true

  maintenance_window       = "Sat:03:00-Sat:04:00"

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  allow_major_version_upgrade = false

  tags = merge(local.common_tags, {Name = "${var.project}-${var.db_name}"})
}

resource "random_password" "random_application_password" {
  length = 32
  special = false
}

resource "aws_secretsmanager_secret" "rds_credentials_application" {
  name = "search-portal/postgres-application"
  description = "Application credentials for the RDS Postgres instance"
}

resource "aws_secretsmanager_secret_version" "postgres_password_application" {
  secret_id     = aws_secretsmanager_secret.rds_credentials_application.id
  secret_string = jsonencode({ password = random_password.random_application_password.result })
}

resource "aws_sns_topic" "rds_metrics" {
  name = "rds-metrics"
  display_name = "RDS Metrics"
}

data "template_file" "sns_cloudwatch_policy" {
  template = file("${path.module}/../cloudwatch/sns-cloudwatch-policy.json.tpl")
  vars = {
    sns_topic_arn = aws_sns_topic.rds_metrics.arn
  }
}

resource "aws_sns_topic_policy" "sns_cloudwatch_policy" {
  arn = aws_sns_topic.rds_metrics.arn

  policy = data.template_file.sns_cloudwatch_policy.rendered
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name                = "rds-cpu"
  dimensions                = {
    "DBInstanceIdentifier" = aws_db_instance.surfpol.identifier
  }
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/RDS"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "60"
  alarm_description         = "This metric monitors postgres cpu utilization"

  alarm_actions = [aws_sns_topic.rds_metrics.arn]
  ok_actions = [aws_sns_topic.rds_metrics.arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_memory" {
  alarm_name                = "rds-memory"
  dimensions                = {
    "DBInstanceIdentifier" = aws_db_instance.surfpol.identifier
  }
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "1"
  metric_name               = "FreeableMemory"
  namespace                 = "AWS/RDS"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "40"
  alarm_description         = "This metric monitors postgres free memory"

  alarm_actions = [aws_sns_topic.rds_metrics.arn]
  ok_actions = [aws_sns_topic.rds_metrics.arn]
}
