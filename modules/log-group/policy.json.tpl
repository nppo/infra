{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:DeleteLogStream",
        "logs:CreateExportTask",
        "logs:DeleteMetricFilter",
        "logs:DeleteSubscriptionFilter",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:DescribeMetricFilters",
        "logs:DescribeSubscriptionFilters",
        "logs:FilterLogEvents",
        "logs:GetLogGroupFields",
        "logs:ListTagsLogGroup",
        "logs:PutMetricFilter",
        "logs:PutSubscriptionFilter",
        "logs:StartQuery"
      ],
      "Resource": ["arn:aws:logs:*:*:log-group:${log_group_name}*"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:GetLogEvents"
      ],
      "Resource": ["arn:aws:logs:*:*:log-group:${log_group_name}:log-stream:*"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:DescribeDestinations",
        "logs:DescribeExportTasks",
        "logs:DescribeQueries",
        "logs:DescribeResourcePolicies",
        "logs:CancelExportTask",
        "logs:GetLogRecord",
        "logs:GetQueryResults",
        "logs:StopQuery",
        "logs:TestMetricFilter"
      ],
      "Resource": ["*"]
    }
  ]
}