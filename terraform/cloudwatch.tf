# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${local.name_prefix}"
  retention_in_days = 7

  tags = {
    Name = "${local.name_prefix}-logs"
  }
}

# CloudWatch Metric Alarms

# High CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${local.name_prefix}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors ECS CPU utilization"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.app.name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]

  tags = {
    Name = "${local.name_prefix}-cpu-high-alarm"
  }
}

# High Memory Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "memory_high" {
  alarm_name          = "${local.name_prefix}-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors ECS memory utilization"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.app.name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]

  tags = {
    Name = "${local.name_prefix}-memory-high-alarm"
  }
}

# Unhealthy Target Alarm
resource "aws_cloudwatch_metric_alarm" "unhealthy_targets" {
  alarm_name          = "${local.name_prefix}-unhealthy-targets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "This metric monitors unhealthy targets"
  treat_missing_data  = "notBreaching"

  dimensions = {
    TargetGroup  = aws_lb_target_group.app.arn_suffix
    LoadBalancer = aws_lb.main.arn_suffix
  }

  alarm_actions = [aws_sns_topic.alerts.arn]

  tags = {
    Name = "${local.name_prefix}-unhealthy-targets-alarm"
  }
}

# High 5XX Error Rate Alarm
resource "aws_cloudwatch_metric_alarm" "high_5xx_errors" {
  alarm_name          = "${local.name_prefix}-high-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "This metric monitors 5XX errors"
  treat_missing_data  = "notBreaching"

  dimensions = {
    TargetGroup  = aws_lb_target_group.app.arn_suffix
    LoadBalancer = aws_lb.main.arn_suffix
  }

  alarm_actions = [aws_sns_topic.alerts.arn]

  tags = {
    Name = "${local.name_prefix}-high-5xx-errors-alarm"
  }
}

# SNS Topic for Alarms
resource "aws_sns_topic" "alerts" {
  name = "${local.name_prefix}-alerts"

  tags = {
    Name = "${local.name_prefix}-alerts-topic"
  }
}

# SNS Topic Subscription (Email - optional)
# Uncomment and set email to receive alerts
# resource "aws_sns_topic_subscription" "alerts_email" {
#   topic_arn = aws_sns_topic.alerts.arn
#   protocol  = "email"
#   endpoint  = "your-email@example.com"
# }

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = local.name_prefix

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", { stat = "Average", label = "CPU" }],
            [".", "MemoryUtilization", { stat = "Average", label = "Memory" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "ECS Resource Utilization"
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", { stat = "Average" }],
            [".", "RequestCount", { stat = "Sum", yAxis = "right" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "ALB Performance"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", { stat = "Sum", label = "2XX" }],
            [".", "HTTPCode_Target_4XX_Count", { stat = "Sum", label = "4XX" }],
            [".", "HTTPCode_Target_5XX_Count", { stat = "Sum", label = "5XX" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "HTTP Response Codes"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", { stat = "Average", label = "Healthy" }],
            [".", "UnHealthyHostCount", { stat = "Average", label = "Unhealthy" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Target Health"
        }
      }
    ]
  })
}

# Log Metric Filter for Errors
resource "aws_cloudwatch_log_metric_filter" "error_count" {
  name           = "${local.name_prefix}-error-count"
  log_group_name = aws_cloudwatch_log_group.app.name
  pattern        = "[time, request_id, level = ERROR*, ...]"

  metric_transformation {
    name      = "ErrorCount"
    namespace = local.name_prefix
    value     = "1"
    unit      = "Count"
  }
}

# Alarm for Error Count
resource "aws_cloudwatch_metric_alarm" "error_count_high" {
  alarm_name          = "${local.name_prefix}-error-count-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ErrorCount"
  namespace           = local.name_prefix
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "This metric monitors application error count"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alerts.arn]

  tags = {
    Name = "${local.name_prefix}-error-count-alarm"
  }
}
