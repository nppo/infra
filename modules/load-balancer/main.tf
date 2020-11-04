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

resource "aws_lb" "surfpol" {
  name = "${var.project}-loadbalancer-${var.env}"
  load_balancer_type = "application"
  ip_address_type = "dualstack"

  enable_deletion_protection = true

  security_groups = [
    var.default_security_group_id,
    var.service_access_security_group_id,
    aws_security_group.load-balancer.id
  ]
  subnets = var.subnet_ids

  tags = merge(local.common_tags, {Name = "${var.project}-${var.env}"})
}

resource "aws_lb_target_group" "surfpol" {
  name = "${var.project}-target-group-${var.env}"
  port = 80
  protocol = "HTTP"
  target_type = "ip"
  vpc_id = var.vpc_id

  tags = merge(local.common_tags, {Name = "${var.project}-${var.env}-target-group"})
}

resource "aws_lb_listener" "http-listener" {
  load_balancer_arn = aws_lb.surfpol.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

data "aws_acm_certificate" "surfpol" {
  domain   = var.domain_name
  statuses = ["ISSUED"]
}

resource "aws_lb_listener" "https-listener" {
  load_balancer_arn = aws_lb.surfpol.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.surfpol.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.surfpol.arn
  }
}

resource "aws_lb_listener_rule" "restrict-admin-to-eduvpn" {
  listener_arn = aws_lb_listener.https-listener.arn
  priority = 1

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.surfpol.arn
  }

  condition {
    path_pattern {
      values = ["/admin/*"]
    }
  }

  condition {
    source_ip {
      values = var.eduvpn_ips
    }
  }
}

resource "aws_lb_listener_rule" "block-admin" {
  listener_arn = aws_lb_listener.https-listener.arn
  priority = 2

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      status_code = 403
    }
  }

  condition {
    path_pattern {
      values = ["/admin/*"]
    }
  }
}
