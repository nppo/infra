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
  lifecycle {
    prevent_destroy = true
  }
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

  tags = merge(local.common_tags, {Name = "${var.project}-${var.env}-public"})
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

resource "aws_network_acl_rule" "https" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 110
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
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

resource "aws_key_pair" "jelmer" {
  key_name = "jelmer"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDL+pYSi8xWN6YdSlNPmBR+Iu5XfRSufXmqrNMesQprU0fSNHE0PiLGv//4a7ZVh6uGCzmqbhQVHbAs50hbODe+Wd5LkNHPnAdu/7gT+Bx3IOwqrZgNyFYxzMRxzKeuxhIwZQjMQNfA79qY+kc/RUX+zaph9fDABbcC5IVDJtpSyPRfx0J3duEbk0opBKLHSV+5gXhyiA39zE7Gxe898AjsKPKClQAUclHYgSK/+U7XrUUMCBJXW/uPVsuO2o0QU9mGxdM0eYf12dP72izYz0wkde5vmVgOpa8UittIUjgrl6+Id2uAvvjIynV46tTOvp8FLe0v0sCsg2ao9tVejxdvYpctg636CtoHsRYbESUDaHrmP5L3NG2UM9J2UIw1e+wpbGGuxvDBTCQK+Pmj6Kn7vTpFfhB3g8+uyWCilVHvtQ0uQ+jjvErODb9GTV9Ozt7LZU1WXtGqC/ODqwg8Y+H5lMCHR4P/yUnP76m3w6Td1h3W+JddZBTGKPkVqtuwbwAxuXC7AH1tFUY6LIqXcnWOv5S59T52CTEMUS1pFY4Anlj7PfBHoNFr/p0+CeLswMRf8SCb+I6G9Cb3ch2BHtKv8aivxuFMmUhjmSrvdda12v5KULwQ+YogXJeahFaoGulc/e81nCPhC0sFFMsggenKCALcENUcDnyx0Lvt9w7myw== Jelmer'siPhone"
}

resource "aws_key_pair" "fako" {
  key_name = "fako"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDSoemGsbpE//hs2yYquV79aIk/7zKAO1j9RBaLs0fUk6eThhOX1ONRAxyxkaR+rZT8PsSVGbH/m+OXCb1pDc4ddMulhjOV9KYUY7h5EXAPN+f0uxmecNahY5qhgtBZAs56NY9ZU5+rIS70F+3K1Acmbwvck7SMRCgCRPFCdO2Qyc3AyQqDSyUoALoqoJlleH282/FqfbAokbs/7MpaTeuqfOMSFLqCzTDQK3C8QsOirdfSORG5OofekJojq9yiBe7xQkLEaTl5EBEVsyMrK+5n2TAXEUfH6NvVqyv50faJ8LXNO4eq3vjmUybIPrbTA0h6p6PheuA+b5TTPexBFtVH fako@Fakos-MacBook-Pro.local"
}

resource "aws_key_pair" "ruben" {
  key_name = "ruben"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCsXnT5E/IXrWD4JIWhyFxuKfeUTzkHjIDdZ/BPErhSw9vWa608aqvtGOZIpqZi/evpHy3WQxxn9z38eZY1LrnOfN6/9It9GTxeWLqVddHpC1d3AlqdA9Jvm02nrqCWgrnnkz0V3shS6TC/DWcPuL+teI79G5cOD4nfGNK7EYUl98iXphuobFuR8MRAzpkBhMWHtPJN49PU0ftYlytaXiKxlDHj5hq9hJAVgBV+CDK77mYDZpJvYJkKqLI1paRMPIowdI2JJCpGPbjhbihZG+tBXAnvUyBJyewcCfgs3RK4sfR1udXQWdOHXbP0mTvQJg+4uzimW3QV6iNh5Ttc6h8n ruben@Rubens-MacBook-Pro.fritz.box"
}

resource "aws_key_pair" "kirsten" {
  key_name = "kirsten"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCtreudPBChpjxasTP9IVQ5rOKMLsetchATrLTQjwQ1eNC/Io4CdBFuSPSE1y+p5UMc5NWYyv3MZ8yR+PmBNzdKpRvhGzOTVlbq0aprlue3nD5q8MjOD5Tzjtmnwrk5RQ9aaWK2hZ7ienVKZ6sh3re4052OheaeftBsqNeOKF7PYXlvZCsNVmcMiTHPdVLpgxCGIdjYJ2xVeuqEqYv7J57fCycnV47iRKHv6bCYuJTh26IaOacNKwhaf9n2+dBeSxZPq9VJBfxyPRgg0w7hqzIKx5Dp6VkDci7y2hxjPslwMCujPK6FIddMwDN42z0MXrIEfdb2GocfxTdvOO0XUINd kruys@zilverline.com"
}
