locals {
  common_tags = {
    Project = var.project
    Environment = var.env
    ProvisionedBy = "Terraform"
  }
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_vpc" "selected" {
  id = var.vpc_id
}

resource "aws_cloudwatch_log_resource_policy" "this" {
  policy_name = "${var.project}-${var.env}-es-${var.domain_name}"
  policy_document = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "es.amazonaws.com"
      },
      "Action": [
        "logs:PutLogEvents",
        "logs:PutLogEventsBatch",
        "logs:CreateLogStream"
      ],
      "Resource": "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${var.log_group_name}:*"
    }
  ]
}
POLICY
}

resource "aws_iam_service_linked_role" "es" {
  aws_service_name = "es.amazonaws.com"
}

resource "aws_security_group" "this" {
  name        = "${var.project}-${var.env}-${var.domain_name}"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = [
      data.aws_vpc.selected.cidr_block
    ]
  }
}

resource "aws_elasticsearch_domain" "this" {
  domain_name           = "${var.project}-${var.env}-${var.domain_name}"
  elasticsearch_version = var.elasticsearch_version

  # TODO: add logic to enable this if correct instance type is selected
  encrypt_at_rest {
    enabled = false
  }

  cluster_config {
    instance_type = var.instance_type
    instance_count = var.instance_count
    dedicated_master_enabled = false
    #dedicated_master_type =
    #dedicated_master_count
    #zone_awareness_config {
    #  availability_zone_count
    #}
    #zone_awareness_enabled
  }

  ebs_options {
    ebs_enabled = true
    volume_type = "gp2"
    volume_size = var.instance_volume_size
  }

  snapshot_options {
    automated_snapshot_start_hour = 3
  }

  node_to_node_encryption {
    enabled = true
  }

  vpc_options {
    subnet_ids = var.subnet_ids
    security_group_ids = ["${aws_security_group.this.id}"]
  }

  domain_endpoint_options {
    enforce_https = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  advanced_options = {
    "rest.action.multi.allow_explicit_index" = "true"
  }

  log_publishing_options {
    cloudwatch_log_group_arn = var.log_group_arn
    log_type                 = "INDEX_SLOW_LOGS"
    enabled                  = true
  }

  log_publishing_options {
    cloudwatch_log_group_arn = var.log_group_arn
    log_type                 = "SEARCH_SLOW_LOGS"
    enabled                  = true
  }

  log_publishing_options {
    cloudwatch_log_group_arn = var.log_group_arn
    log_type                 = "ES_APPLICATION_LOGS"
    enabled                  = true
  }

  tags = merge(local.common_tags, {Domain = "${var.project}-${var.env}-${var.domain_name}"})

  depends_on = [aws_iam_service_linked_role.es]
}