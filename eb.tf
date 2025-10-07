resource "aws_cloudwatch_event_rule" "drs_source_sever_stalled" {
  name = "drs-source-server-stalled"
  description = "Capture DRS Source Server Stalled events"

  event_pattern = jsonencode({
    "source": ["aws.drs"],
    "detail-type": ["DRS Source Server Data Replication Stalled Change"],
    "detail.state": ["STALLED"]
  })

  tags = {
    "Project" = "drs"
  }
}

resource "aws_sqs_queue" "drs_source_server_stalled_queue" {
  name                       = "drs-source-server-stalled-queue"
  visibility_timeout_seconds = 30
  message_retention_seconds  = 86400

  tags = {
    "Project" = "drs"
  }
}

resource "aws_cloudwatch_event_target" "drs_source_server_stalled_target" {
  rule = aws_cloudwatch_event_rule.drs_source_sever_stalled.name
  arn  = module.recovery_sfn.drs_recovery_sfn_arn
  role_arn = module.recovery_sfn.drs_recovery_role_arn

  input_transformer {
    input_paths = {
      "SourceServerArn": "$.resources[0]",
      "State": "$.detail.state"
    }

    input_template = <<EOF
{
  "SourceServerArn": "<SourceServerArn>",
  "State": "<State>"
}
EOF
  }
  
  dead_letter_config {
    arn = aws_sqs_queue.drs_source_server_stalled_queue.arn
  }
}