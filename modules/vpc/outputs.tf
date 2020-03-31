output "vpc_id" {
  value = aws_vpc.this.id
  description = "The id for this VPC"
}

output "private_subnet_ids" {
  value = values(aws_subnet.private).*.id
  description = "The subnet ids for the private subnets"
}