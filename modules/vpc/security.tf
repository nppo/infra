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

resource "aws_security_group" "aws-services-access" {
  name        = "aws-services-access"
  description = "Grants access to AWS services like: RDS and ElastiCache"
  vpc_id      = aws_vpc.this.id
}

resource "aws_security_group" "aws-services-protect" {
  name = "aws-services-protect"
  description = "Protects AWS services like: RDS and ElastiCache"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [
      aws_security_group.aws-services-access.id
    ]
  }

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    security_groups = [aws_security_group.aws-services-access.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [aws_security_group.aws-services-access.id]
  }
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


resource "aws_network_acl_rule" "inbound-smtp" {
  network_acl_id = aws_network_acl.public.id
  rule_number     = 121
  protocol        = "tcp"
  rule_action     = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port       = 25
  to_port         = 25
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

resource "aws_network_acl_rule" "egress-smtp" {
  network_acl_id = aws_network_acl.public.id
  egress         = true
  rule_number    = 140
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 25
  to_port        = 25
}


resource "aws_network_acl_rule" "egress-smtp-ipv6" {
  network_acl_id = aws_network_acl.public.id
  egress          = true
  rule_number     = 141
  protocol        = "tcp"
  rule_action     = "allow"
  ipv6_cidr_block = "::/0"
  from_port       = 25
  to_port         = 25
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

  egress {
    protocol   = "tcp"
    rule_no    = 130
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 25
    to_port    = 25
  }

  egress {
    protocol   = "tcp"
    rule_no    = 140
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 9011
    to_port    = 9011
  }

  tags = merge(local.common_tags, {Name = "${var.project}-private"})
}

resource "aws_key_pair" "keys" {
  for_each = var.public_keys

  key_name = each.key
  public_key = each.value
}
