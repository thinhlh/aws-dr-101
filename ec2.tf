resource "aws_instance" "linux" {
  ami = local.linux_ami
  instance_type = local.instance_type
  vpc_security_group_ids = [aws_security_group.windows_sg.id]
  subnet_id = aws_subnet.project_subnet_private_us_east_1["us-east-1a"].id
  key_name  = data.aws_key_pair.ec2_window_key.key_name
  iam_instance_profile = aws_iam_instance_profile.project_ec2_profile.name

  root_block_device {
    volume_size = 8
    delete_on_termination = true
    encrypted = true
    volume_type = "gp3"
    kms_key_id = aws_kms_key.ebs_encryption_key.arn

    tags = {
      "Project" = "drs"
      "Name"    = "drs-linux-default-volume"
    }
  }

  ebs_block_device {
    device_name = "/dev/xvdb"
    volume_size = 9
    delete_on_termination = true
    encrypted = true
    volume_type = "gp3"
    kms_key_id = aws_kms_key.ebs_encryption_key.arn

    tags = {
      "Project" = "drs"
      "Name"    = "drs-linux-secondary-volume"
    }
  }

  user_data_base64 = base64encode(templatefile("${path.module}/scripts/user_data.sh.tpl", {
    region = var.aws_region
  }))

  tags = {
    Name    = "drs-linux-server-us-east-1a"
    Project = "drs"
  }
}

resource "aws_instance" "windows" {
  ami = local.ami
  iam_instance_profile = aws_iam_instance_profile.project_ec2_profile.name
  instance_type = local.instance_type
  vpc_security_group_ids = [aws_security_group.windows_sg.id]
  subnet_id = aws_subnet.project_subnet_private_us_east_1["us-east-1a"].id
  key_name  = data.aws_key_pair.ec2_window_key.key_name

  user_data_base64 = base64encode(templatefile("${path.module}/scripts/user_data.ps1.tpl", {
    region = var.aws_region
  }))

  root_block_device {
    volume_size = 30
    delete_on_termination = true
    encrypted = true
    volume_type = "gp3"
    kms_key_id = aws_kms_key.ebs_encryption_key.arn

    tags = {
      "Project" = "drs"
      "Name"    = "drs-windows-default-volume"
    }
  }

  ebs_block_device {
    device_name = "/dev/sdb"
    volume_size = 31
    delete_on_termination = true
    encrypted = true
    volume_type = "gp3"
    kms_key_id = aws_kms_key.ebs_encryption_key.arn

    tags = {
      "Project" = "drs"
      "Name"    = "drs-windows-secondary-volume"
    }
  }

  tags = {
    Project = "drs"
    Name = "drs-windows-server-us-east-1a"
  }
}