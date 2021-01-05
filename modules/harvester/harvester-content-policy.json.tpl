{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ListObjectsInBucket",
            "Effect": "Allow",
            "Action": ["s3:ListBucket"],
            "Resource": ["${harvester_content_bucket_arn}"]
        },
        {
            "Sid": "AllObjectActions",
            "Effect": "Allow",
            "Action": ["s3:*Object*"],
            "Resource": ["${harvester_content_bucket_arn}/*"]
        },
        {
          "Effect": "Allow",
          "Action": [
            "s3:GetBucketLocation"
          ],
          "Resource": [
            "${harvester_content_bucket_arn}"
          ]
        }
    ]
}
