resource "aws_launch_template" "window_launch_template" {
  name = "drs-windows-launch-template"

  image_id      = local.ami
  instance_type = local.instance_type

  vpc_security_group_ids = [aws_security_group.windows_sg.id]

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 30
      encrypted   = true
      volume_type = "gp3"
      kms_key_id  = aws_kms_key.ebs_encryption_key.arn
    }
  }
  block_device_mappings {
    device_name = "/dev/xvdb"
    ebs {
      volume_size = 30
      volume_type = "gp3"
      encrypted   = true
      kms_key_id  = aws_kms_key.ebs_encryption_key.arn
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.project_ec2_profile.name
  }

  user_data = base64encode(templatefile("${path.module}/scripts/user_data.ps1.tpl", {
    region = var.aws_region
  }))
}

resource "aws_instance" "windows" {
  launch_template {
    id = aws_launch_template.window_launch_template.id
  }
  subnet_id = aws_subnet.project_subnet_private_us_east_1["us-east-1a"].id

  tags = {
    Name = "drs-windows-server-us-east-1a"
  }
}
