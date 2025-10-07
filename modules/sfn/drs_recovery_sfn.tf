resource "aws_sfn_state_machine" "drs_recovery_sfn" {
    name = "drs-recovery-sfn"
    role_arn = data.aws_iam_role.drs_recovery_role.arn
    type = "STANDARD"
    definition = templatefile("${path.module}/templates/DRSRecovery.asl.json.tpl", {
        
    })

    tags = {
      "Project" = "drs"
    }

    encryption_configuration {
      type = "AWS_OWNED_KEY"
    }

    logging_configuration {
      level = "ALL"
      include_execution_data = true
      log_destination = "${aws_cloudwatch_log_group.drs_recovery_sfn_log_group.arn}:*"
    }
}