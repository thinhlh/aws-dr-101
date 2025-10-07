data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "lambda_replicate_source_template_to_drs" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:GetLaunchTemplateData",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:CreateLaunchTemplateVersion",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "lambda_replicate_source_template_to_drs_policy" {
  name   = "lambda-replicate-source-template-to-drs-policy"
  policy = data.aws_iam_policy_document.lambda_replicate_source_template_to_drs.json

  tags = {
    "Project" = "drs"
  }
  
}

resource "aws_iam_role" "drs_recovery_launch_template_sync_lambda_role" {
  name               = "drs-recovery-launch-template-sync-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = {
    "Project" = "drs"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.drs_recovery_launch_template_sync_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_drs_readonly" {
  role       = aws_iam_role.drs_recovery_launch_template_sync_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticDisasterRecoveryReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_ec2_readonly" {
  role       = aws_iam_role.drs_recovery_launch_template_sync_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_ec2_get_template_data" {
  role       = aws_iam_role.drs_recovery_launch_template_sync_lambda_role.name
  policy_arn = aws_iam_policy.lambda_replicate_source_template_to_drs_policy.arn
}