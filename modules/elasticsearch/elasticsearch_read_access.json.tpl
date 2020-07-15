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
      "Action": [
          "es:ESHttpPOST"
      ],
      "Resource": [
          "${elasticsearch_arn}/latest-nl,latest-en/_search",
          "${elasticsearch_arn}/latest-en,latest-nl/_search",
          "${elasticsearch_arn}/latest-en/_search",
          "${elasticsearch_arn}/latest-nl/_search"
      ]
    }
  ]
}
