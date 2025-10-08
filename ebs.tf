# resource "aws_ebs_volume" "window_default_volume" {
#   availability_zone = aws_subnet.project_subnet_private_us_east_1["us-east-1a"].availability_zone
#   size              = 8
#   encrypted         = true
#   type              = "gp3"
#   kms_key_id        = aws_kms_key.ebs_encryption_key.arn
#   tags = {
#     "Name"    = "drs-windows-default-volume"
#     "Project" = "drs"
#   }
# }

# resource "aws_ebs_volume" "linux_default_volume" {
#   availability_zone = aws_subnet.project_subnet_private_us_east_1["us-east-1a"].availability_zone
#   size              = 8
#   encrypted         = true
#   type              = "gp3"
#   kms_key_id        = aws_kms_key.ebs_encryption_key.arn
#   tags = {
#     "Name"    = "drs-linux-default-volume"
#     "Project" = "drs"
#   }
# }

# resource "aws_ebs_volume" "linux_secondary_volume" {
#   availability_zone = aws_subnet.project_subnet_private_us_east_1["us-east-1a"].availability_zone
#   size              = 8
#   encrypted         = true
#   type              = "gp3"
#   kms_key_id        = aws_kms_key.ebs_encryption_key.arn
#   tags = {
#     "Name"    = "drs-linux-secondary-volume"
#     "Project" = "drs"
#   }

# }