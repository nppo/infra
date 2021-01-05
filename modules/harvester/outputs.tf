output "harvester_access_security_group_id" {
  value = aws_security_group.access_harvester.id
  description = "The id of the security group that may access the harvester"
}

output "harvester_bucket_arn" {
  value = aws_s3_bucket.harvester_content_bucket.arn
  description = "The arn of the harvester content bucket"
}
