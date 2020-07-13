{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "es:ESHttpGet"
      ],
      "Resource": [
        "${elasticsearch_arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": "iam:PassRole",
      "Resource": [
        "AmazonESReadOnlyAccess"
      ]
    }
  ]
}
