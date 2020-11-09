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
  tags = merge(local.common_tags, {Name = "${var.project}"})
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

resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(local.common_tags, {Name = "${var.project}-default"})

}

# based on https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-best-practices.html#nacl-rules-scenario-2
resource "aws_network_acl" "public" {
  vpc_id = aws_vpc.this.id
  subnet_ids = values(aws_subnet.public)[*].id

  tags = merge(local.common_tags, {Name = "${var.project}-public"})
}

resource "aws_network_acl_rule" "http" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "http-ipv6" {
  network_acl_id = aws_network_acl.public.id
  rule_number     = 101
  protocol        = "tcp"
  rule_action     = "allow"
  ipv6_cidr_block = "::/0"
  from_port       = 80
  to_port         = 80
}

resource "aws_network_acl_rule" "https" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 110
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "https-ipv6" {
  network_acl_id = aws_network_acl.public.id
  rule_number     = 111
  protocol        = "tcp"
  rule_action     = "allow"
  ipv6_cidr_block = "::/0"
  from_port       = 443
  to_port         = 443
}

resource "aws_network_acl_rule" "range" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 120
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "eduvpn-ssh" {
  network_acl_id = aws_network_acl.public.id
  count       = length(var.ipv4_eduvpn_ips)
  protocol    = "tcp"
  rule_number = 130 + count.index
  rule_action = "allow"
  cidr_block  = element(var.ipv4_eduvpn_ips, count.index)
  from_port   = 22
  to_port     = 22
}

resource "aws_network_acl_rule" "eduvpn-ssh-ipv6" {
  network_acl_id = aws_network_acl.public.id
  count       = length(var.ipv6_eduvpn_ips)
  protocol    = "tcp"
  rule_number = 134 + count.index
  rule_action = "allow"
  ipv6_cidr_block  = element(var.ipv6_eduvpn_ips, count.index)
  from_port   = 22
  to_port     = 22
}

resource "aws_network_acl_rule" "egress-http" {
  network_acl_id = aws_network_acl.public.id
  egress         = true
  rule_number    = 100
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "egress-http-ipv6" {
  network_acl_id = aws_network_acl.public.id
  egress          = true
  rule_number     = 101
  protocol        = "tcp"
  rule_action     = "allow"
  ipv6_cidr_block = "::/0"
  from_port       = 80
  to_port         = 80
}

resource "aws_network_acl_rule" "egress-https" {
  network_acl_id = aws_network_acl.public.id
  egress         = true
  rule_number    = 110
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "egress-https-ipv6" {
  network_acl_id = aws_network_acl.public.id
  egress          = true
  rule_number     = 111
  protocol        = "tcp"
  rule_action     = "allow"
  ipv6_cidr_block = "::/0"
  from_port       = 443
  to_port         = 443
}

resource "aws_network_acl_rule" "egress-cidr" {
  network_acl_id = aws_network_acl.public.id
  egress         = true
  protocol       = -1
  rule_number    = 120
  rule_action    = "allow"
  cidr_block     = var.cidr
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "egress-range" {
  network_acl_id = aws_network_acl.public.id
  egress         = true
  rule_number    = 130
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "egress-range-ipv6" {
  network_acl_id = aws_network_acl.public.id
  egress          = true
  rule_number     = 131
  protocol        = "tcp"
  rule_action     = "allow"
  ipv6_cidr_block = "::/0"
  from_port       = 1024
  to_port         = 65535
}

# based on https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-best-practices.html#nacl-rules-scenario-2
resource "aws_network_acl" "private" {
  vpc_id = aws_vpc.this.id
  subnet_ids = values(aws_subnet.private)[*].id

  # --- ingress ---
  ingress {
    protocol   = "-1"
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

  tags = merge(local.common_tags, {Name = "${var.project}-private"})
}

resource "aws_key_pair" "keys" {
  for_each = var.public_keys

  key_name = each.key
  public_key = each.value
}
