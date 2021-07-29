locals {
  common_tags = {
    Project = var.project
    Environment = var.env
    ProvisionedBy = "Terraform"
  }
}

resource "aws_security_group" "load-balancer" {
  name = "${var.project}-${var.env}-load-balancer"
  description = "Protects the load balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description = "HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(local.common_tags, {Name = "${var.project}-${var.env}-load-balancer"})
}

resource "aws_lb" "nppo" {
  name = "${var.project}-loadbalancer-${var.env}"
  load_balancer_type = "application"
  ip_address_type = "dualstack"
  drop_invalid_header_fields = true
  enable_deletion_protection = true

  security_groups = [
    var.default_security_group_id,
    var.harvester_access_security_group_id,
    var.search_access_security_group_id,
    aws_security_group.load-balancer.id
  ]
  subnets = var.subnet_ids

  tags = merge(local.common_tags, {Name = "${var.project}-${var.env}"})
}

resource "aws_lb_target_group" "harvester-target" {
  name = "harvester-target-group"
  port = 80
  protocol = "HTTP"
  target_type = "ip"
  vpc_id = var.vpc_id

  tags = merge(local.common_tags, {Name = "harvester-target-group"})
}

resource "aws_lb_target_group" "search-target" {
  name = "search-target-group"
  port = 80
  protocol = "HTTP"
  target_type = "ip"
  vpc_id = var.vpc_id

  tags = merge(local.common_tags, {Name = "search-target-group"})
}

resource "aws_lb_listener" "http-listener" {
  load_balancer_arn = aws_lb.nppo.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.harvester-target.arn
  }
}

resource "aws_lb_listener_rule" "search-default" {
  listener_arn = aws_lb_listener.http-listener.arn
  priority = 4

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.search-target.arn
  }

  condition {
    host_header {
      values = ["fakoberkers.nl", "nppo.fakoberkers.nl"]
    }
  }
}
