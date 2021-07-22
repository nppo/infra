locals {
  common_tags = {
    Project = var.project
    Environment = var.env
    ProvisionedBy = "Terraform"
  }
}

data "aws_vpc" "selected" {
  id = var.vpc_id
}

resource "aws_iam_service_linked_role" "es" {
  aws_service_name = "es.amazonaws.com"
}

resource "aws_cloudwatch_log_group" "this" {
  name = "elasticsearch"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_resource_policy" "this" {
  policy_name = "elasticsearch-logs"
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
      "Resource": "arn:aws:logs:*"
    }
  ]
}
POLICY
}

resource "aws_kms_key" "elasticsearch_encryption_key" {
  description = "Elasticsearch encryption key"
}

resource "aws_kms_alias" "elasticsearch_encryption_key_alias" {
  name          = "alias/elasticsearch-encryption-key"
  target_key_id = aws_kms_key.elasticsearch_encryption_key.key_id
}

resource "aws_elasticsearch_domain" "this" {
  domain_name           = "${var.project}-${var.domain_name}"
  elasticsearch_version = var.elasticsearch_version

  encrypt_at_rest {
    enabled = true
    kms_key_id = aws_kms_key.elasticsearch_encryption_key.key_id
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
    subnet_ids = [var.subnet_id]
    security_group_ids = [aws_security_group.this.id]
  }

  domain_endpoint_options {
    enforce_https = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  advanced_options = {
    "rest.action.multi.allow_explicit_index" = "true"
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.this.arn
    log_type                 = "INDEX_SLOW_LOGS"
    enabled                  = true
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.this.arn
    log_type                 = "SEARCH_SLOW_LOGS"
    enabled                  = true
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.this.arn
    log_type                 = "ES_APPLICATION_LOGS"
    enabled                  = true
  }

  tags = merge(local.common_tags, {Domain = "${var.project}-${var.domain_name}"})

  depends_on = [aws_iam_service_linked_role.es]
}

resource "aws_elasticsearch_domain_policy" "main" {
  domain_name = aws_elasticsearch_domain.this.domain_name

  access_policies = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "es:*",
      "Resource": "${aws_elasticsearch_domain.this.arn}/*"
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "elasticsearch_full_access" {
  name        = "NPPOElasticSearchFullAccess"
  description = "Policy for full access to NPPO elasticsearch cluster"
  policy = templatefile(
    "${path.module}/elasticsearch_full_access.json.tpl",
    { elasticsearch_arn: aws_elasticsearch_domain.this.arn }
  )
}

resource "aws_iam_role_policy_attachment" "superuser_elastic" {
  role = var.superuser_task_role_name
  policy_arn = aws_iam_policy.elasticsearch_full_access.arn
}

resource "aws_iam_policy" "elasticsearch_read_access" {
  name        = "NPPOElasticSearchReadAccess"
  description = "Policy for read-access to NPPO elasticsearch cluster"
  policy = templatefile(
    "${path.module}/elasticsearch_read_access.json.tpl",
    { elasticsearch_arn: aws_elasticsearch_domain.this.arn }
  )
}

resource "aws_iam_role_policy_attachment" "application_elastic" {
  role = var.application_task_role_name
  policy_arn = aws_iam_policy.elasticsearch_read_access.arn
}

resource "aws_iam_role_policy_attachment" "application_read_elastic" {
  role = var.application_task_role_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonESReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "harvester_elastic" {
  role = var.harvester_task_role_name
  policy_arn = aws_iam_policy.elasticsearch_full_access.arn
}
