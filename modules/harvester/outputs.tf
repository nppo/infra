output "harvester_access_security_group_id" {
  value = aws_security_group.access_harvester.id
  description = "The id of the security group that may access the harvester"
}

output "harvester_bucket_arn" {
  value = aws_s3_bucket.harvester_content_bucket.arn
  description = "The arn of the harvester content bucket"
}

output "harvester_bucket_name" {
  value = aws_s3_bucket.harvester_content_bucket.id
  description = "The name of the harvester content bucket"
}

output "harvester_api_key_arn" {
  value = aws_secretsmanager_secret_version.harvester_key_version.arn
  description = "The ARN of the secret that holds the internal harvester API key"
}

output "hva_pure_api_key_arn" {
  value = aws_secretsmanager_secret_version.pure_hva_key.arn
  description = "The ARN of the secret that holds the HvA Pure API key"
}
