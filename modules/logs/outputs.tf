output "firehose_security_group" {
  value = aws_security_group.firehose.id
  description = "The id of the firehose security group"
}
