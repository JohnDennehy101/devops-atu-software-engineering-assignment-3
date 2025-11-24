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
