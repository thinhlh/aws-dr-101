resource "aws_cloudwatch_event_rule" "drs_source_sever_not_stalled" {
  name = "drs-source-server-not-stalled"
  description = "Capture DRS Source Server Not Stalled events"

  event_pattern = jsonencode({
    "source": ["aws.drs"],
    "detail-type": ["DRS Source Server Data Replication Stalled Change"]
  })

  tags = {
    "Project" = "drs"
  }
}

resource "aws_cloudwatch_event_target" "drs_source_server_not_stalled_target" {
  rule = aws_cloudwatch_event_rule.drs_source_sever_not_stalled.name
  arn  = aws_lambda_function.drs_recovery_launch_template_sync_lambda.arn
}