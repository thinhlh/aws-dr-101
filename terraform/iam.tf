# IAM roles and policies for DRS and EC2 instances

# IAM role for EC2 instances
resource "aws_iam_role" "ec2_instance_role" {
  name = "${var.project_name}-ec2-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-ec2-instance-role"
    Environment = var.environment
  }
}

# IAM policy for DRS agent
resource "aws_iam_policy" "drs_agent_policy" {
  name        = "${var.project_name}-drs-agent-policy"
  description = "Policy for DRS agent to communicate with AWS services"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "drs:*",
          "ec2:DescribeInstances",
          "ec2:DescribeImages",
          "ec2:DescribeVolumes",
          "ec2:DescribeSnapshots",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs",
          "ec2:CreateSnapshot",
          "ec2:CreateTags",
          "ec2:ModifyInstanceAttribute",
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:SendCommand",
          "ssm:GetCommandInvocation",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-drs-agent-policy"
    Environment = var.environment
  }
}

# Attach DRS policy to EC2 instance role
resource "aws_iam_role_policy_attachment" "ec2_drs_policy" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = aws_iam_policy.drs_agent_policy.arn
}

# Attach SSM managed policy for remote management
resource "aws_iam_role_policy_attachment" "ec2_ssm_policy" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach CloudWatch agent policy
resource "aws_iam_role_policy_attachment" "ec2_cloudwatch_policy" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Instance profile for EC2 instances
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.project_name}-ec2-instance-profile"
  role = aws_iam_role.ec2_instance_role.name

  tags = {
    Name        = "${var.project_name}-ec2-instance-profile"
    Environment = var.environment
  }
}

# IAM role for DRS service
resource "aws_iam_role" "drs_service_role" {
  name = "${var.project_name}-drs-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "drs.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-drs-service-role"
    Environment = var.environment
  }
}

# DRS service policy
resource "aws_iam_policy" "drs_service_policy" {
  name        = "${var.project_name}-drs-service-policy"
  description = "Policy for DRS service operations"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "iam:PassRole",
          "iam:CreateServiceLinkedRole",
          "kms:CreateGrant",
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:GenerateDataKey",
          "kms:ReEncrypt*"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-drs-service-policy"
    Environment = var.environment
  }
}

# Attach DRS service policy
resource "aws_iam_role_policy_attachment" "drs_service_policy_attachment" {
  role       = aws_iam_role.drs_service_role.name
  policy_arn = aws_iam_policy.drs_service_policy.arn
}