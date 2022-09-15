locals {
  common_tags = {
    Project = var.project
    Environment = var.env
    ProvisionedBy = "Terraform"
  }

  # maps subnets to the supplied availability zones using the modulo operator
  public_subnets_azs = {
    for subnet in var.public_subnets:
    subnet => var.azs[index(var.public_subnets, subnet) % length(var.azs)]
  }

  # maps subnets to the supplied availability zones using the modulo operator
  private_subnets_azs = {
    for subnet in var.private_subnets:
    subnet => var.azs[index(var.private_subnets, subnet) % length(var.azs)]
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
  assign_generated_ipv6_cidr_block = true
}

resource "aws_subnet" "public" {
  for_each = local.public_subnets_azs

  vpc_id = aws_vpc.this.id
  cidr_block = each.key
  availability_zone = each.value
  map_public_ip_on_launch = true
  ipv6_cidr_block = cidrsubnet(aws_vpc.this.ipv6_cidr_block, 8, index(var.public_subnets, each.key) + 1)

  tags = merge(local.common_tags, {Name = "${var.project}-public-${index(var.public_subnets, each.key)}"})
}

resource "aws_subnet" "private" {
  for_each = local.private_subnets_azs

  vpc_id = aws_vpc.this.id
  cidr_block = each.key
  availability_zone = each.value

  tags = merge(local.common_tags, {Name = "${var.project}-private-${index(var.private_subnets, each.key)}"})
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = merge(local.common_tags, {Name = var.project})
}

resource "aws_egress_only_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
}

# Create elastic ip's for the nat gateways
resource "aws_eip" "this" {
  for_each = local.azs_to_subnets

  vpc = true
  tags = merge(local.common_tags, {Name = "${var.project}-${index(var.azs, each.key)}"})

  depends_on = [aws_internet_gateway.this]
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_nat_gateway" "this" {
  for_each = local.azs_to_subnets

  allocation_id = aws_eip.this[each.key].id
  subnet_id = aws_subnet.public[each.value].id

  tags = merge(local.common_tags, {Name = "${var.project}-${index(var.azs, each.key)}"})

  depends_on = [aws_internet_gateway.this]
}

# provides a route to the internet via the internet gateway
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

  tags = merge(local.common_tags, {Name = "${var.project}-public"})
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

  tags = merge(local.common_tags, {Name = "${var.project}-private-${index(var.azs, each.key)}"})
}

# associate each private route table to the correct private subnet
resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id = each.value.id
  route_table_id = aws_route_table.private[each.value.availability_zone].id
}
