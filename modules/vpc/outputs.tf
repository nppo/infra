output "vpc_id" {
  value = aws_vpc.this.id
  description = "The id for this VPC"
}

output "private_subnet_ids" {
  value = values(aws_subnet.private).*.id
  description = "The subnet ids for the private subnets"
}

output "public_subnet_ids" {
  value = values(aws_subnet.public).*.id
  description = "The subnet ids for the public subnets"
}

output "default_security_group_id" {
  value = aws_default_security_group.this.id
  description = "The id of the default VPC security group"
}
