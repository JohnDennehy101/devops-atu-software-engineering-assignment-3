#######################################################
# IAM Policy Definition for ECR and CloudWatch Access #
#######################################################

resource "aws_iam_policy" "task_execute_role_policy" {
  name        = "${local.prefix}-task-execute-role-policy"
  path        = "/"
  description = "Enable ECS to work with images and send logs"
  policy      = file("./templates/ecs/task-execute-role-policy.json")
}

#####################################
# IAM Role Definition for ECS tasks #
#####################################

resource "aws_iam_role" "task_execute_role" {
  name               = "${local.prefix}-task-execute-role"
  assume_role_policy = file("./templates/ecs/task-assume-role-policy.json")
}

#########################
# Attach policy to role #
#########################

resource "aws_iam_role_policy_attachment" "task_execute_role" {
  role       = aws_iam_role.task_execute_role.name
  policy_arn = aws_iam_policy.task_execute_role_policy.arn
}

#####################################
# IAM Role Definition for ECS Tasks #
#####################################

resource "aws_iam_role" "task_role" {
  name               = "${local.prefix}-task-role"
  assume_role_policy = file("./templates/ecs/task-assume-role-policy.json")
}

#################################################
# CloudWatch log group definition for ECS tasks #
#################################################

resource "aws_cloudwatch_log_group" "api_logs" {
  name = "${local.prefix}-api"
}

resource "aws_cloudwatch_log_group" "frontend_logs" {
  name = "${local.prefix}-frontend"
}

##########################
# ECS cluster definition #
##########################

resource "aws_ecs_cluster" "primary" {
  name = "${local.prefix}-cluster"
}

#######################
# ECS task definition #
#######################

resource "aws_ecs_task_definition" "primary" {
  family                   = "${local.prefix}-primary"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  task_role_arn            = aws_iam_role.task_role.arn
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.task_execute_role.arn
  container_definitions = jsonencode([
    {
      name      = "api"
      image     = var.ecr_api_image
      essential = true
      environment = [
        {
          name  = "NOTES_DB_DSN"
          value = "postgres://${var.database_username}:${urlencode(var.database_password)}@${aws_db_instance.primary.address}:${aws_db_instance.primary.port}/${aws_db_instance.primary.db_name}?sslmode=require"
        },
        {
          name  = "FRONTEND_BASE_URL"
          value = "https://${var.subdomain[terraform.workspace]}.${var.dns_zone_name}"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.api_logs.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "api"
        }
      },
      portMappings = [{
        containerPort = 4000
        hostPort      = 4000
        protocol      = "tcp"
      }]
    },
    {
      name      = "frontend"
      image     = var.ecr_frontend_image
      essential = true
      environment = [
        {
          name  = "VITE_API_BASE_URL"
          value = "https://${var.subdomain[terraform.workspace]}.${var.dns_zone_name}"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.frontend_logs.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "frontend"
        }
      },
      portMappings = [{
        containerPort = 80
        hostPort      = 80
        protocol      = "tcp"
      }]
    },
  ])

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}

#############################################
# Security Group definition for ECS service #
#############################################

resource "aws_security_group" "ecs_service" {
  description = "Access for ecs service"
  name        = "${local.prefix}-ecs-service"
  vpc_id      = aws_vpc.primary.id
}

resource "aws_security_group_rule" "ecs_ingress_from_lb_frontend" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lb.id
  security_group_id        = aws_security_group.ecs_service.id
  description              = "HTTP from ALB"
}

resource "aws_security_group_rule" "ecs_ingress_from_lb_api" {
  type                     = "ingress"
  from_port                = 4000
  to_port                  = 4000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lb.id
  security_group_id        = aws_security_group.ecs_service.id
  description              = "API from ALB"
}

resource "aws_security_group_rule" "ecs_egress_to_rds" {
  type              = "egress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = [aws_vpc.primary.cidr_block]
  security_group_id = aws_security_group.ecs_service.id
  description       = "ECS egress for RDS"
}

resource "aws_security_group_rule" "ecs_egress_vpc_tcp" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs_service.id
  description       = "HTTPS TCP communication"
}

##########################
# ECS service definition #
##########################

resource "aws_ecs_service" "primary" {
  name                   = "${local.prefix}-primary"
  cluster                = aws_ecs_cluster.primary.name
  task_definition        = aws_ecs_task_definition.primary.arn
  desired_count          = 2
  launch_type            = "FARGATE"
  platform_version       = "1.4.0"
  enable_execute_command = true
  depends_on = [
    aws_lb_listener_rule.api,
    aws_lb_listener.primary_http
  ]
  network_configuration {
    subnets         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_groups = [aws_security_group.ecs_service.id]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "frontend"
    container_port   = 80
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "api"
    container_port   = 4000
  }
}
