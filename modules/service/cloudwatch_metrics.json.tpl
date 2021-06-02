{
  "Version": "2012-10-17",
    "Statement": [
    {
      "Effect": "Allow",
      "Action": ["cloudwatch:GetMetricData", "cloudwatch:GetMetricStatistics", "cloudwatch:ListMetrics"],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "cloudwatch:namespace": "AWS/Route53"
        }
      }
    }
    ]
}
