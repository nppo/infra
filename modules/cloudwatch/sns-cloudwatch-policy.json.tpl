{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Allow_Publish_Alarms",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "cloudwatch.amazonaws.com"
        ]
      },
      "Action": "sns:Publish",
      "Resource": "${sns_topic_arn}"
    }
  ]
}
