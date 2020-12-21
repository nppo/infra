{
  "Version": "2012-10-17",
    "Statement": [
    {
      "Sid": "ListObjectsInBucket",
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": ["${bucket_arn}"]
    },
    {
      "Sid": "AllObjectActions",
      "Effect": "Allow",
      "Action": ["s3:*Object*"],
      "Resource": ["${bucket_arn}/*"]
    },
    {
      "Sid": "GetPreviewFromHarvesterBucket",
      "Effect": "Allow",
      "Action": ["s3:GetObject"],
      "Resource": ["${harvester_bucket_arn}/previews/*"]
    }
  ]
}
