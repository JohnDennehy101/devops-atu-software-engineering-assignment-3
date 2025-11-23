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
    path = "/healthcheck"
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

######################################
# Load Balancer Listeners Definition #
######################################

resource "aws_lb_listener" "primary_http" {
  load_balancer_arn = aws_lb.primary.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn

    # redirect {
    #   port        = 443
    #   protocol    = "HTTPS"
    #   status_code = "HTTP_301"
    # }
  }
}

resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.primary_http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }

  condition {
    path_pattern {
      values = ["/api/*", "/healthcheck"]
    }
  }
}


# resource "aws_lb_listener" "static_site_https" {
#   load_balancer_arn = aws_lb.static_site.arn
#   port              = 443
#   protocol          = "HTTPS"

#   certificate_arn = aws_acm_certificate_validation.cert.certificate_arn

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.static_site.arn
#   }
# }

