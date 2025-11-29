###########################################
# Load Balancer Security Group Definition #
###########################################

resource "aws_security_group" "lb" {
  description = "Security group for the ALB"
  name        = "${local.prefix}-alb-access"
  vpc_id      = aws_vpc.primary.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "lb_egress_to_ecs_frontend" {
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs_service.id
  security_group_id        = aws_security_group.lb.id
  description              = "HTTP to ECS frontend"
}

resource "aws_security_group_rule" "lb_egress_to_ecs_api" {
  type                     = "egress"
  from_port                = 4000
  to_port                  = 4000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs_service.id
  security_group_id        = aws_security_group.lb.id
  description              = "HTTP to ECS API"
}

resource "aws_security_group_rule" "lb_egress_to_prometheus" {
  type                     = "egress"
  from_port                = 9090
  to_port                  = 9090
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.prometheus.id
  security_group_id        = aws_security_group.lb.id
  description              = "HTTP to Prometheus"
}

resource "aws_security_group_rule" "lb_egress_to_grafana" {
  type                     = "egress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.grafana.id
  security_group_id        = aws_security_group.lb.id
  description              = "HTTP to Grafana"
}

############################
# Load Balancer Definition #
############################

resource "aws_lb" "primary" {
  name               = "${local.prefix}-lb"
  load_balancer_type = "application"
  subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]
  security_groups = [
    aws_security_group.lb.id
  ]
}

#########################################
# Load Balancer Target Groups Definition #
#########################################

resource "aws_lb_target_group" "api" {
  name        = "${local.prefix}-api"
  protocol    = "HTTP"
  vpc_id      = aws_vpc.primary.id
  target_type = "ip"
  port        = 4000

  health_check {
    path                = "/v1/healthcheck"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}

resource "aws_lb_target_group" "frontend" {
  name        = "${local.prefix}-frontend"
  protocol    = "HTTP"
  vpc_id      = aws_vpc.primary.id
  target_type = "ip"
  port        = 80

  health_check {
    path = "/"
  }
}

resource "aws_lb_target_group" "prometheus" {
  name        = "${local.prefix}-prometheus"
  protocol    = "HTTP"
  vpc_id      = aws_vpc.primary.id
  target_type = "ip"
  port        = 9090

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 10
    interval            = 30
    matcher             = "200"
  }
}

resource "aws_lb_target_group" "grafana" {
  name        = "${local.prefix}-grafana"
  protocol    = "HTTP"
  vpc_id      = aws_vpc.primary.id
  target_type = "ip"
  port        = 3000

  health_check {
    path                = "/api/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}

######################################
# Load Balancer Listeners Definition #
######################################

resource "aws_lb_listener" "primary_http" {
  load_balancer_arn = aws_lb.primary.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "primary_https" {
  load_balancer_arn = aws_lb.primary.arn
  port              = 443
  protocol          = "HTTPS"

  certificate_arn = aws_acm_certificate_validation.cert.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

resource "aws_lb_listener_certificate" "grafana" {
  listener_arn    = aws_lb_listener.primary_https.arn
  certificate_arn = aws_acm_certificate_validation.grafana_cert.certificate_arn
}

resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.primary_https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }

  condition {
    path_pattern {
      values = ["/api/*", "/v1/*", "/healthcheck"]
    }
  }
}

resource "aws_lb_listener_rule" "prometheus" {
  listener_arn = aws_lb_listener.primary_https.arn
  priority     = 50

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prometheus.arn
  }

  condition {
    path_pattern {
      values = ["/prometheus", "/prometheus/*"]
    }
  }
}

resource "aws_lb_listener_rule" "grafana" {
  listener_arn = aws_lb_listener.primary_https.arn
  priority     = 40

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana.arn
  }

  condition {
    host_header {
      values = [aws_route53_record.grafana.name]
    }
  }
}