

data "archive_file" "drs_recovery_launch_template_sync_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/scripts/drs-recovery-launch-template-sync"
  output_path = "${path.module}/scripts/drs-recovery-launch-template-sync/drs-recovery-launch-template-sync.zip"
}

resource "aws_cloudwatch_log_group" "drs_recovery_launch_template_sync_log_group" {
  name              = "/drs/lambda/drs-recovery-launch-template-sync"
  retention_in_days = 14

  tags = {
    "Project" = "drs"
  }
}

resource "aws_lambda_function" "drs_recovery_launch_template_sync_lambda" {
  filename         = data.archive_file.drs_recovery_launch_template_sync_lambda_zip.output_path
  package_type     = "Zip"
  function_name    = "drs_recovery_launch_template_sync_lambda"
  description      = "Lambda function to sync DRS EC2 recovery template to source server launch template"
  handler          = "index.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = data.archive_file.drs_recovery_launch_template_sync_lambda_zip.output_base64sha256
  role             = aws_iam_role.drs_recovery_launch_template_sync_lambda_role.arn
  logging_config {
    log_group = aws_cloudwatch_log_group.drs_recovery_launch_template_sync_log_group.name
    log_format = "JSON"
  }

  tags = {
    "Project" = "drs"
  }
}