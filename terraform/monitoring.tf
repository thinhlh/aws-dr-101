# CloudWatch Monitoring and SNS Notifications

# SNS Topic for DR alerts
resource "aws_sns_topic" "dr_alerts" {
  provider = aws.primary
  name     = "${var.project_name}-dr-alerts"

  tags = {
    Name        = "${var.project_name}-dr-alerts"
    Environment = var.environment
  }
}

# SNS Topic for secondary region
resource "aws_sns_topic" "dr_alerts_secondary" {
  provider = aws.secondary
  name     = "${var.project_name}-dr-alerts-secondary"

  tags = {
    Name        = "${var.project_name}-dr-alerts-secondary"
    Environment = var.environment
  }
}

# CloudWatch Log Group for DRS
resource "aws_cloudwatch_log_group" "drs_logs" {
  provider          = aws.primary
  name              = "/aws/drs/${var.project_name}"
  retention_in_days = 30

  tags = {
    Name        = "${var.project_name}-drs-logs"
    Environment = var.environment
  }
}

# CloudWatch Dashboard for DR monitoring
resource "aws_cloudwatch_dashboard" "dr_dashboard" {
  provider       = aws.primary
  dashboard_name = "${var.project_name}-dr-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.windows_primary.id],
            [".", "StatusCheckFailed", ".", "."],
            [".", "StatusCheckFailed_Instance", ".", "."],
            [".", "StatusCheckFailed_System", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.primary_region
          title   = "Primary Instance Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.windows_secondary.id],
            [".", "StatusCheckFailed", ".", "."],
            [".", "StatusCheckFailed_Instance", ".", "."],
            [".", "StatusCheckFailed_System", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.secondary_region
          title   = "Secondary Instance Metrics"
          period  = 300
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 12
        width  = 24
        height = 6

        properties = {
          query  = "SOURCE '/aws/drs/${var.project_name}' | fields @timestamp, @message | sort @timestamp desc | limit 20"
          region = var.primary_region
          title  = "DRS Logs"
        }
      }
    ]
  })
}

# CloudWatch Alarm for Primary Instance
resource "aws_cloudwatch_metric_alarm" "primary_instance_status" {
  provider            = aws.primary
  alarm_name          = "${var.project_name}-primary-instance-status"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "0"
  alarm_description   = "This metric monitors primary instance status check"
  alarm_actions       = [aws_sns_topic.dr_alerts.arn]

  dimensions = {
    InstanceId = aws_instance.windows_primary.id
  }

  tags = {
    Name        = "${var.project_name}-primary-alarm"
    Environment = var.environment
  }
}

# CloudWatch Alarm for High CPU on Primary Instance
resource "aws_cloudwatch_metric_alarm" "primary_instance_cpu" {
  provider            = aws.primary
  alarm_name          = "${var.project_name}-primary-instance-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors primary instance CPU utilization"
  alarm_actions       = [aws_sns_topic.dr_alerts.arn]

  dimensions = {
    InstanceId = aws_instance.windows_primary.id
  }

  tags = {
    Name        = "${var.project_name}-primary-cpu-alarm"
    Environment = var.environment
  }
}

# CloudWatch Alarm for Secondary Instance
resource "aws_cloudwatch_metric_alarm" "secondary_instance_status" {
  provider            = aws.secondary
  alarm_name          = "${var.project_name}-secondary-instance-status"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "0"
  alarm_description   = "This metric monitors secondary instance status check"
  alarm_actions       = [aws_sns_topic.dr_alerts_secondary.arn]

  dimensions = {
    InstanceId = aws_instance.windows_secondary.id
  }

  tags = {
    Name        = "${var.project_name}-secondary-alarm"
    Environment = var.environment
  }
}

# CloudWatch Log Stream for application logs
resource "aws_cloudwatch_log_stream" "app_logs" {
  provider       = aws.primary
  name           = "${var.project_name}-application-logs"
  log_group_name = aws_cloudwatch_log_group.drs_logs.name
}