{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "es:ESHttpGet",
        "es:Describe*",
        "es:List*"
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
    },
    {
      "Effect": "Allow",
      "Action": [
        "es:ESHttpGet",
        "es:ESHttpPost"
      ],
      "Resource": [
        "${elasticsearch_arn}/search-results",
        "${elasticsearch_arn}/search-results/*",
        "${elasticsearch_arn}/harvest-logs*",
        "${elasticsearch_arn}/document-logs*",
        "${elasticsearch_arn}/service-logs*"
      ]
    }
  ]
}
