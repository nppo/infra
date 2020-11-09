resource "aws_cloudwatch_log_group" "firelens" {
  name = "firelens-container"
}

resource "aws_s3_bucket" "logs_s3" {
  bucket = var.bucket_name
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
      security_group_ids = [var.firehose_security_group]
      role_arn           = aws_iam_role.firehose_role.arn
    }
  }
}
