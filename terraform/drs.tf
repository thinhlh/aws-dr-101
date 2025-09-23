# DRS (Elastic Disaster Recovery) Configuration

# DRS Replication Configuration Set
resource "aws_drs_replication_configuration_template" "main" {
  count = var.enable_drs ? 1 : 0

  associate_default_security_group        = false
  bandwidth_throttling                    = 0
  create_public_ip                        = false
  data_plane_routing                      = "PRIVATE_IP"
  default_large_staging_disk_type         = "GP3"
  ebs_encryption                          = "DEFAULT"
  replication_server_instance_type        = var.replication_instance_type
  replication_servers_security_groups_ids = [aws_security_group.drs_replication.id]
  staging_area_subnet_id                  = aws_subnet.secondary_private.id
  staging_area_tags = {
    Name        = "${var.project_name}-drs-staging"
    Environment = var.environment
  }
  use_dedicated_replication_server = false

  tags = {
    Name        = "${var.project_name}-drs-replication-template"
    Environment = var.environment
  }
}

# KMS Key for DRS encryption
resource "aws_kms_key" "drs" {
  description             = "KMS key for DRS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow DRS service"
        Effect = "Allow"
        Principal = {
          Service = "drs.amazonaws.com"
        }
        Action = [
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
    Name        = "${var.project_name}-drs-kms-key"
    Environment = var.environment
  }
}

# KMS Key Alias
resource "aws_kms_alias" "drs" {
  name          = "alias/${var.project_name}-drs"
  target_key_id = aws_kms_key.drs.key_id
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}

# Note: DRS Launch Configuration Template is managed through AWS Console
# The aws_drs_launch_configuration_template resource is not available in the current provider version
# Launch configurations will need to be created manually in the DRS console or via AWS CLI

# Placeholder for launch configuration - to be created manually
locals {
  drs_launch_config_note = "Launch configuration template must be created in DRS console"
}