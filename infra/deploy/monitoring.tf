#######################################
# Cloudwatch API Dashboard Definition #
#######################################

resource "aws_cloudwatch_dashboard" "api" {
  dashboard_name = "${local.prefix}-api"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 10
        height = 5
        properties = {
          metrics = [
            ["ECS/ContainerInsights", "CpuUtilized", "ServiceName", aws_ecs_service.primary.name, "ClusterName", aws_ecs_cluster.primary.name, "ContainerName", "api"],
            [".", "MemoryUtilized", ".", ".", ".", ".", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "API Container CPU and Memory usage"
          period  = 300
          stat    = "Average"
        }
      },
      {
        type   = "metric"
        x      = 10
        y      = 0
        width  = 10
        height = 5
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "TargetGroup", split("/", aws_lb_target_group.api.arn)[length(split("/", aws_lb_target_group.api.arn)) - 1], "LoadBalancer", split("/", aws_lb.primary.arn)[length(split("/", aws_lb.primary.arn)) - 1]],
            [".", "HTTPCode_Target_2XX_Count", ".", ".", ".", "."],
            [".", "HTTPCode_Target_4XX_Count", ".", ".", ".", "."],
            [".", "HTTPCode_Target_5XX_Count", ".", ".", ".", "."],
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "API Requests & Status Codes"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 5
        width  = 10
        height = 5
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "TargetGroup", split("/", aws_lb_target_group.api.arn)[length(split("/", aws_lb_target_group.api.arn)) - 1], "LoadBalancer", split("/", aws_lb.primary.arn)[length(split("/", aws_lb.primary.arn)) - 1]],
            [".", "HealthyHostCount", ".", ".", ".", "."],
            [".", "UnHealthyHostCount", ".", ".", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "API Health & Response Time"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 10
        y      = 5
        width  = 10
        height = 5
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", aws_db_instance.primary.id],
            [".", "DatabaseConnections", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "RDS CPU & Connections"
          period  = 300
        }
      }
    ]
  })
}


############################################
# Cloudwatch Frontend Dashboard Definition #
############################################

resource "aws_cloudwatch_dashboard" "frontend" {
  dashboard_name = "${local.prefix}-frontend"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 10
        height = 5
        properties = {
          metrics = [
            ["ECS/ContainerInsights", "CpuUtilized", "ServiceName", aws_ecs_service.primary.name, "ClusterName", aws_ecs_cluster.primary.name, "ContainerName", "frontend"],
            [".", "MemoryUtilized", ".", ".", ".", ".", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "Frontend Container CPU and Memory usage"
          period  = 300
          stat    = "Average"
        }
      },
      {
        type   = "metric"
        x      = 10
        y      = 0
        width  = 10
        height = 5
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "TargetGroup", split("/", aws_lb_target_group.frontend.arn)[length(split("/", aws_lb_target_group.frontend.arn)) - 1], "LoadBalancer", split("/", aws_lb.primary.arn)[length(split("/", aws_lb.primary.arn)) - 1]],
            [".", "HTTPCode_Target_2XX_Count", ".", ".", ".", "."],
            [".", "HTTPCode_Target_4XX_Count", ".", ".", ".", "."],
            [".", "HTTPCode_Target_5XX_Count", ".", ".", ".", "."],
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "Frontend Requests & Status Codes"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 5
        width  = 20
        height = 5
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "TargetGroup", split("/", aws_lb_target_group.frontend.arn)[length(split("/", aws_lb_target_group.frontend.arn)) - 1], "LoadBalancer", split("/", aws_lb.primary.arn)[length(split("/", aws_lb.primary.arn)) - 1]],
            [".", "HealthyHostCount", ".", ".", ".", "."],
            [".", "UnHealthyHostCount", ".", ".", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "Frontend Health & Response Time"
          period  = 300
        }
      },
    ]
  })
}

######################################
# Cloudwatch Alarms Definition - ECS #
######################################

resource "aws_cloudwatch_metric_alarm" "ecs_high_cpu" {
  alarm_name          = "${local.prefix}-ecs-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Monitor ECS CPU use"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ServiceName = aws_ecs_service.primary.name
    ClusterName = aws_ecs_cluster.primary.name
  }

  tags = {
    Name = "${local.prefix}-ecs-high-cpu-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_high_memory" {
  alarm_name          = "${local.prefix}-ecs-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Monitor ECS memory use"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ServiceName = aws_ecs_service.primary.name
    ClusterName = aws_ecs_cluster.primary.name
  }

  tags = {
    Name = "${local.prefix}-ecs-high-memory-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_task_failures" {
  alarm_name          = "${local.prefix}-ecs-task-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "StoppedTaskCount"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Monitor ECS task failures"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ServiceName = aws_ecs_service.primary.name
    ClusterName = aws_ecs_cluster.primary.name
  }

  tags = {
    Name = "${local.prefix}-ecs-task-failures-alarm"
  }
}

######################################
# Cloudwatch Alarms Definition - ALB #
######################################

resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "${local.prefix}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Monitor ALB 5xx errors"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = split("/", aws_lb.primary.arn)[length(split("/", aws_lb.primary.arn)) - 1]
  }

  tags = {
    Name = "${local.prefix}-alb-5xx-errors-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_high_response_time" {
  alarm_name          = "${local.prefix}-alb-high-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Average"
  threshold           = 2
  alarm_description   = "Monitor ALB response time"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = split("/", aws_lb.primary.arn)[length(split("/", aws_lb.primary.arn)) - 1]
  }

  tags = {
    Name = "${local.prefix}-alb-high-response-time-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  alarm_name          = "${local.prefix}-alb-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "Monitor unhealthy hosts"
  treat_missing_data  = "notBreaching"

  dimensions = {
    TargetGroup  = split("/", aws_lb_target_group.api.arn)[length(split("/", aws_lb_target_group.api.arn)) - 1]
    LoadBalancer = split("/", aws_lb.primary.arn)[length(split("/", aws_lb.primary.arn)) - 1]
  }

  tags = {
    Name = "${local.prefix}-alb-unhealthy-hosts-alarm"
  }
}

######################################
# Cloudwatch Alarms Definition - RDS #
######################################

resource "aws_cloudwatch_metric_alarm" "rds_high_cpu" {
  alarm_name          = "${local.prefix}-rds-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Monitor RDS CPU use"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.primary.id
  }

  tags = {
    Name = "${local.prefix}-rds-high-cpu-alarm"
  }
}


resource "aws_cloudwatch_metric_alarm" "rds_high_connections" {
  alarm_name          = "${local.prefix}-rds-high-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 20
  alarm_description   = "Monitor RDS connection count"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.primary.id
  }

  tags = {
    Name = "${local.prefix}-rds-high-connections-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_low_storage" {
  alarm_name          = "${local.prefix}-rds-low-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 2000000000
  alarm_description   = "Monitor RDS free storage space (2GB threshold)"
  treat_missing_data  = "notBreaching"
  unit                = "Bytes"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.primary.id
  }

  tags = {
    Name = "${local.prefix}-rds-low-storage-alarm"
  }
}

##################################################
# Cloudwatch log group Definition for Prometheus #
##################################################

resource "aws_cloudwatch_log_group" "prometheus_logs" {
  name = "${local.prefix}-prometheus"
}

############################################
# Security group Definition for Prometheus #
############################################

resource "aws_security_group" "prometheus" {
  name        = "${local.prefix}-prometheus"
  description = "Security group for Prometheus"
  vpc_id      = aws_vpc.primary.id

  ingress {
    from_port       = 9090
    to_port         = 9090
    protocol        = "tcp"
    security_groups = [aws_security_group.lb.id]
    description     = "Allow Prometheus UI from Load Balancer"
  }

  ingress {
    from_port       = 9090
    to_port         = 9090
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_service.id]
    description     = "Allow Prometheus metrics obtained from API"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.prefix}-prometheus"
  }
}

######################################
# ECS Task Definition for Prometheus #
######################################

resource "aws_ecs_task_definition" "prometheus" {
  family                   = "${local.prefix}-prometheus"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  task_role_arn            = aws_iam_role.task_role.arn
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.task_execute_role.arn

  container_definitions = jsonencode([
    {
      name       = "prometheus"
      image      = var.ecr_prometheus_image
      essential  = true
      entryPoint = ["sh", "-c"]
      command = [
        <<-EOT
          while [ ! -d /etc/prometheus ]; do sleep 1; done
          
          if [ ! -f /etc/prometheus/prometheus.yml ]; then
            cat > /etc/prometheus/prometheus.yml <<'EOF'
          global:
            scrape_interval: 15s
            evaluation_interval: 15s
          
          scrape_configs:
            - job_name: "api"
              metrics_path: "/v1/metrics"
              static_configs:
                - targets: ["${aws_lb.primary.dns_name}:443"]
                  labels:
                    service: "api"
                    environment: "${terraform.workspace}"
              scheme: "https"
              tls_config:
                insecure_skip_verify: true
          
            - job_name: "prometheus"
              static_configs:
                - targets: ["localhost:9090"]
          EOF
            chmod 644 /etc/prometheus/prometheus.yml
          fi
          
          exec /bin/prometheus \
            --config.file=/etc/prometheus/prometheus.yml \
            --storage.tsdb.path=/prometheus \
            --web.external-url=/prometheus/ \
            --storage.tsdb.retention.time=7d
        EOT
      ]
      environment = [
        {
          name  = "PROMETHEUS_STORAGE_PATH"
          value = "/prometheus"
        }
      ]
      mountPoints = [
        {
          sourceVolume  = "prometheus-config"
          containerPath = "/etc/prometheus"
          readOnly      = false
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.prometheus_logs.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "prometheus"
        }
      }
      portMappings = [{
        containerPort = 9090
        hostPort      = 9090
        protocol      = "tcp"
      }]
    }
  ])

  volume {
    name = "prometheus-config"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.prometheus_config.id
      root_directory     = "/"
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.prometheus_config.id
        iam             = "ENABLED"
      }
    }
  }

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}

#########################################
# ECS Service Definition for Prometheus #
#########################################

resource "aws_ecs_service" "prometheus" {
  name                   = "${local.prefix}-prometheus"
  cluster                = aws_ecs_cluster.primary.name
  task_definition        = aws_ecs_task_definition.prometheus.arn
  desired_count          = 1
  launch_type            = "FARGATE"
  platform_version       = "1.4.0"
  enable_execute_command = true

  depends_on = [
    aws_lb_listener_rule.prometheus,
    aws_lb_listener.primary_http
  ]

  network_configuration {
    subnets         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_groups = [aws_security_group.prometheus.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.prometheus.arn
    container_name   = "prometheus"
    container_port   = 9090
  }
}

###############################################
# Cloudwatch log group Definition for Grafana #
###############################################

resource "aws_cloudwatch_log_group" "grafana_logs" {
  name = "${local.prefix}-grafana"
}

#########################################
# Security group Definition for Grafana #
#########################################

resource "aws_security_group" "grafana" {
  name        = "${local.prefix}-grafana"
  description = "Security group for Grafana"
  vpc_id      = aws_vpc.primary.id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.lb.id]
    description     = "Allow Grafana UI from Load Balancer"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.prefix}-grafana"
  }
}

###################################
# ECS Task Definition for Grafana #
###################################

resource "aws_ecs_task_definition" "grafana" {
  family                   = "${local.prefix}-grafana"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  task_role_arn            = aws_iam_role.task_role.arn
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.task_execute_role.arn

  container_definitions = jsonencode([
    {
      name      = "grafana"
      image     = var.ecr_grafana_image
      essential = true
      entryPoint = ["sh", "-c"]
      command = [
        <<-EOT
          mkdir -p /etc/grafana/provisioning/datasources
          mkdir -p /etc/grafana/provisioning/dashboards
          
          PROMETHEUS_URL="https://${var.subdomain[terraform.workspace]}.${var.dns_zone_name}/prometheus"
          cat > /etc/grafana/provisioning/datasources/prometheus.yml <<EOF
          apiVersion: 1
          datasources:
            - name: Prometheus
              type: prometheus
              access: proxy
              url: ${PROMETHEUS_URL}
              isDefault: true
              editable: true
              jsonData:
                tlsSkipVerify: true
          EOF
          
          cat > /etc/grafana/provisioning/dashboards/dashboard.yml <<'EOF'
          ${file("${path.module}/grafana-provisioning/dashboards/dashboard.yml")}
          EOF
          
          cat > /etc/grafana/provisioning/dashboards/api_metrics.json <<'EOF'
          ${file("${path.module}/grafana-provisioning/dashboards/api_metrics.json")}
          EOF
          
          exec /run.sh
        EOT
      ]
      environment = [
        {
          name  = "GF_SECURITY_ADMIN_PASSWORD"
          value = var.grafana_admin_password
        },
        {
          name  = "GF_SERVER_ROOT_URL"
          value = coalesce(var.grafana_server_url, "https://${var.subdomain[terraform.workspace]}.${var.dns_zone_name}/grafana")
        },
        {
          name  = "GF_USERS_ALLOW_SIGN_UP"
          value = tostring(var.grafana_users_allow_sign_up)
        },
        {
          name  = "GF_INSTALL_PLUGINS"
          value = ""
        }
      ]
      mountPoints = [
        {
          sourceVolume  = "grafana-data"
          containerPath = "/var/lib/grafana"
          readOnly      = false
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.grafana_logs.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "grafana"
        }
      }
      portMappings = [{
        containerPort = 3000
        hostPort      = 3000
        protocol      = "tcp"
      }]
    }
  ])

  volume {
    name = "grafana-data"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.grafana_data.id
      root_directory     = "/"
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.grafana_data.id
        iam             = "ENABLED"
      }
    }
  }

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}

######################################
# ECS Service Definition for Grafana #
######################################

resource "aws_ecs_service" "grafana" {
  name                   = "${local.prefix}-grafana"
  cluster                = aws_ecs_cluster.primary.name
  task_definition        = aws_ecs_task_definition.grafana.arn
  desired_count          = 1
  launch_type            = "FARGATE"
  platform_version       = "1.4.0"
  enable_execute_command = true

  depends_on = [
    aws_lb_listener_rule.grafana,
    aws_lb_listener.primary_http
  ]

  network_configuration {
    subnets         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_groups = [aws_security_group.grafana.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.grafana.arn
    container_name   = "grafana"
    container_port   = 3000
  }
}