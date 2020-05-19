locals {
  common_tags = {
    Project = var.project
    Environment = var.env
    ProvisionedBy = "Terraform"
  }

  # maps subnets to the supplied availability zones using the modulo operator
  public_subnets_azs = {
    for subnet in var.public_subnets:
    subnet => var.azs["${index(var.public_subnets, subnet) % length(var.azs)}"]
  }

  # maps subnets to the supplied availability zones using the modulo operator
  private_subnets_azs = {
    for subnet in var.private_subnets:
    subnet => var.azs["${index(var.private_subnets, subnet) % length(var.azs)}"]
  }

  # mapping of availability zones to the subnet we will provision the nat gateway in
  # each zone gets a nat gateway to provide redundancy because nat gateways are limited
  # to a single az
  azs_to_subnets = zipmap(values(local.public_subnets_azs), keys(local.public_subnets_azs))
}

resource "aws_vpc" "this" {
  cidr_block = var.cidr
  tags = merge(local.common_tags, {Name = "${var.project}-${var.env}"})

  enable_dns_support = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "public" {
  for_each = local.public_subnets_azs

  vpc_id = aws_vpc.this.id
  cidr_block = each.key
  availability_zone = each.value
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {Name = "${var.project}-${var.env}-public-${index(var.public_subnets, each.key)}"})
}

resource "aws_subnet" "private" {
  for_each = local.private_subnets_azs

  vpc_id = aws_vpc.this.id
  cidr_block = each.key
  availability_zone = each.value

  tags = merge(local.common_tags, {Name = "${var.project}-${var.env}-private-${index(var.private_subnets, each.key)}"})
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = merge(local.common_tags, {Name = "${var.project}-${var.env}"})
}

resource "aws_egress_only_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
}

# Create elastic ip's for the nat gateways
resource "aws_eip" "this" {
  for_each = local.azs_to_subnets

  vpc = true
  tags = merge(local.common_tags, {Name = "${var.project}-${var.env}-${index(var.azs, each.key)}"})

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  for_each = local.azs_to_subnets

  allocation_id = aws_eip.this[each.key].id
  subnet_id = aws_subnet.public[each.value].id

  tags = merge(local.common_tags, {Name = "${var.project}-${var.env}-${index(var.azs, each.key)}"})

  depends_on = [aws_internet_gateway.this]
}

# provides a route to the internet via the internet gatway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(local.common_tags, {Name = "${var.project}-${var.env}-public"})
}

# associate the public route table to all public subnets
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id = each.value.id
  route_table_id = aws_route_table.public.id
}

# create a private route table for each availability zone that provides
# a route to the internet via the nat gateway we have provisioned for this
# specific availability zone
resource "aws_route_table" "private" {
  for_each = local.azs_to_subnets
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[each.key].id
  }

  route {
    ipv6_cidr_block = "::/0"
    egress_only_gateway_id = aws_egress_only_internet_gateway.this.id
  }

  tags = merge(local.common_tags, {Name = "${var.project}-${var.env}-private-${index(var.azs, each.key)}"})
}

# associate each private route table to the correct private subnet
resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id = each.value.id
  route_table_id = aws_route_table.private[each.value.availability_zone].id
}

resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  ingress {
    description = "Opens unencrypted traffic to balancer"
    protocol  = "tcp"
    self      = false
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    from_port = 80
    to_port   = 80
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(local.common_tags, {Name = "${var.project}-${var.env}"})

}

# based on https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-best-practices.html#nacl-rules-scenario-2
resource "aws_network_acl" "public" {
  vpc_id = aws_vpc.this.id
  subnet_ids = values(aws_subnet.public)[*].id

  # --- ingress ---
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 130
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  # --- egress ---
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  egress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  egress {
    protocol   = -1
    rule_no    = 120
    action     = "allow"
    cidr_block = var.cidr
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = "tcp"
    rule_no    = 130
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  tags = merge(local.common_tags, {Name = "${var.project}-${var.env}-public"})
}

# based on https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-best-practices.html#nacl-rules-scenario-2
resource "aws_network_acl" "private" {
  vpc_id = aws_vpc.this.id
  subnet_ids = values(aws_subnet.private)[*].id

  # --- ingress ---
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.cidr
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # --- egress ---
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  egress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  egress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = var.cidr
    from_port  = 1024
    to_port    = 65535
  }

  tags = merge(local.common_tags, {Name = "${var.project}-${var.env}-private"})
}
