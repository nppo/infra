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

  tags = merge(local.common_tags, {Name = "${var.project}-${var.env}-${var.db_name}"})
}

resource "aws_db_parameter_group" "this" {
  name   = "${var.project}-${var.env}-${var.db_name}"
  family = "postgres11"

  parameter {
    name  = "timezone"
    value = "Europe/Amsterdam"
  }

  tags = merge(local.common_tags, {Name = "${var.project}-${var.env}-${var.db_name}"})
}

resource "random_password" "password" {
  length = 16
  special = true
}

resource "aws_security_group" "access" {
  name        = "${var.project}-${var.env}-${var.db_name}-access"
  description = "Allows access to the ${var.project}-${var.env}-${var.db_name} database"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {Name = "${var.project}-${var.env}-${var.db_name}-access"})
}

resource "aws_security_group" "db" {
  name = "${var.project}-${var.env}-${var.db_name}-db"
  description = "Protects the ${var.project}-${var.env}-${var.db_name} database"
  vpc_id      = var.vpc_id

  ingress {
    description = "TLS from VPC"
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

  tags = merge(local.common_tags, {Name = "${var.project}-${var.env}-${var.db_name}-db"})
}

resource "aws_db_instance" "this" {
  identifier               = "${var.project}-${var.env}-${var.db_name}"
  db_subnet_group_name     = aws_db_subnet_group.this.name
  multi_az                 = false
  vpc_security_group_ids   = [aws_security_group.db.id]

  allocated_storage        = 20
  max_allocated_storage    = 1000
  storage_type             = "gp2"
  engine                   = "postgres"
  engine_version           = "11.6"
  instance_class           = "db.t2.micro"
  name                     = var.db_name
  #storage_encrypted        = true

  parameter_group_name     = aws_db_parameter_group.this.name

  username                 = "postgres"
  password                 = random_password.password.result

  final_snapshot_identifier = "${var.project}-${var.env}-${var.db_name}-final"
  backup_retention_period  = 35
  backup_window            = "02:00-03:00"
  delete_automated_backups = true

  #deletion_protection      = true

  maintenance_window       = "Sat:03:00-Sat:04:00"

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  allow_major_version_upgrade = false

  tags = merge(local.common_tags, {Name = "${var.project}-${var.env}-${var.db_name}"})
}
