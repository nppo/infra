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
    var.middleware_access_security_group_id,
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

resource "aws_lb_target_group" "middleware-target" {
  name = "middleware-target-group"
  port = 80
  protocol = "HTTP"
  target_type = "ip"
  vpc_id = var.vpc_id

  tags = merge(local.common_tags, {Name = "middleware-target-group"})
}

resource "aws_lb_listener" "http-listener" {
  load_balancer_arn = aws_lb.nppo.arn
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

data "aws_acm_certificate" "main" {
  domain   = "*.${var.domain_name}"
  statuses = ["ISSUED"]
  most_recent = true
}

resource "aws_lb_listener" "https-listener" {
  load_balancer_arn = aws_lb.nppo.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = data.aws_acm_certificate.main.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.harvester-target.arn
  }
}

resource "aws_lb_listener_rule" "search-default" {
  listener_arn = aws_lb_listener.https-listener.arn
  priority = 4

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.search-target.arn
  }

  condition {
    host_header {
      values = ["search.${var.domain_name}"]
    }
  }
}

resource "aws_lb_listener_rule" "middleware-default" {
  listener_arn = aws_lb_listener.https-listener.arn
  priority = 5

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.middleware-target.arn
  }

  condition {
    host_header {
      values = ["sources.${var.domain_name}"]
    }
  }
}

resource "aws_route53_zone" "publinova" {
  name = var.domain_name
}

resource "aws_route53_record" "harvester-ip4" {
  zone_id = aws_route53_zone.publinova.zone_id
  name    = "harvester.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.nppo.dns_name
    zone_id                = aws_lb.nppo.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "harvester-ip6" {
  zone_id = aws_route53_zone.publinova.zone_id
  name    = "harvester.${var.domain_name}"
  type    = "AAAA"

  alias {
    name                   = aws_lb.nppo.dns_name
    zone_id                = aws_lb.nppo.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "search-ip4" {
  zone_id = aws_route53_zone.publinova.zone_id
  name    = "search.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.nppo.dns_name
    zone_id                = aws_lb.nppo.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "search-ip6" {
  zone_id = aws_route53_zone.publinova.zone_id
  name    = "search.publinova.nl"
  type    = "AAAA"

  alias {
    name                   = aws_lb.nppo.dns_name
    zone_id                = aws_lb.nppo.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "middleware-ip4" {
  zone_id = aws_route53_zone.publinova.zone_id
  name    = "sources.publinova.nl"
  type    = "A"

  alias {
    name                   = aws_lb.nppo.dns_name
    zone_id                = aws_lb.nppo.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "middleware-ip6" {
  zone_id = aws_route53_zone.publinova.zone_id
  name    = "sources.publinova.nl"
  type    = "AAAA"

  alias {
    name                   = aws_lb.nppo.dns_name
    zone_id                = aws_lb.nppo.zone_id
    evaluate_target_health = true
  }
}
