variable "name" {}
variable "threshold" {}
variable "pattern" {}
variable "actions_enabled" {
  description = "Whether the alarm actions are enabled"
  type        = bool
  default     = true
}

resource "aws_cloudwatch_log_metric_filter" "this" {
  name           = var.name
  log_group_name = "CloudTrail/logs"
  pattern        = var.pattern

  metric_transformation {
    name      = var.name
    namespace = "LogMetrics"
    value     = 1
  }
}

resource "aws_cloudwatch_metric_alarm" "this" {
  alarm_name          = var.name
  metric_name         = aws_cloudwatch_log_metric_filter.this.metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.this.metric_transformation[0].namespace
  threshold           = var.threshold
  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Sum"
  evaluation_periods  = 1
  period              = 300
  treat_missing_data  = "notBreaching"
  actions_enabled     = var.actions_enabled
  alarm_actions       = [data.aws_sns_topic.this.arn]
}

data "aws_sns_topic" "this" {
  name = "alert-mail"
}
