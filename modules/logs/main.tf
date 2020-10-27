resource "aws_cloudwatch_log_group" "firelens" {
  name = "firelens-container"
}

resource "aws_s3_bucket" "logs_s3" {
  bucket = "surfpol-logs-backup"
  acl    = "private"
}

resource "aws_iam_role" "firehose_role" {
  name = "firehose_logs_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "firehose-elasticsearch" {
  name   = "elasticsearch"
  role   = aws_iam_role.firehose_role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "es:*"
      ],
      "Resource": [
        "${var.elasticsearch_arn}",
        "${var.elasticsearch_arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeVpcs",
        "ec2:DescribeVpcAttribute",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeNetworkInterfaces",
        "ec2:CreateNetworkInterface",
        "ec2:CreateNetworkInterfacePermission",
        "ec2:DeleteNetworkInterface"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}

resource "aws_security_group" "firehose" {
  name        = "Firehose"
  description = "Allow outbound traffic to elasticsearch"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "outbound_to_es" {
  security_group_id        = aws_security_group.firehose.id
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  type                     = "egress"
  source_security_group_id = var.elasticsearch_security_group
}

resource "aws_kinesis_firehose_delivery_stream" "logs_to_es" {
  depends_on = [aws_iam_role_policy.firehose-elasticsearch]

  name        = "logs_to_es"
  destination = "elasticsearch"
  s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.logs_s3.arn
  }
  elasticsearch_configuration {
    domain_arn = var.elasticsearch_arn
    role_arn   = aws_iam_role.firehose_role.arn
    index_name = "logs"

    vpc_config {
      subnet_ids         = var.subnet_ids
      security_group_ids = [aws_security_group.firehose.id]
      role_arn           = aws_iam_role.firehose_role.arn
    }
  }
}
