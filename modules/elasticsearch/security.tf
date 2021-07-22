resource "aws_security_group" "this" {
  name        = "${var.project}-elasticsearch-${var.domain_name}"
  description = "Allow inbound traffic to elasticsearch cluster from VPC"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = [
      data.aws_vpc.selected.cidr_block
    ]

    security_groups = [
      aws_security_group.access.id
    ]
  }

  tags = merge(local.common_tags, {Domain = "${var.project}-elasticsearch-${var.domain_name}"})
}

resource "aws_security_group" "access" {
  name        = "${var.project}-${var.env}-elasticsearch-access"
  description = "Allows access to theElasticSearch cluster"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {Domain = "${var.project}-elasticsearch-${var.domain_name}"})
}

resource "aws_security_group_rule" "outbound_to_es" {
  security_group_id        = aws_security_group.access.id
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  type                     = "egress"
  source_security_group_id = aws_security_group.this.id
}

