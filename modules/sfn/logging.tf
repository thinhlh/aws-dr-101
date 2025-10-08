resource "aws_cloudwatch_log_group" "drs_recovery_sfn_log_group" {
  name              = "/drs/sfn/drs-recovery-sfn"
  retention_in_days = 14

  tags = {
    "Project" = "drs"
  }
}