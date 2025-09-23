# EC2 Instances Configuration

# User data script for Windows instances
locals {
  windows_user_data = base64encode(templatefile("${path.module}/scripts/windows_userdata.ps1", {
    project_name = var.project_name
    environment  = var.environment
  }))
}

# Primary Windows EC2 Instance
resource "aws_instance" "windows_primary" {
  provider                    = aws.primary
  ami                         = data.aws_ami.windows_primary.id
  instance_type               = var.instance_type
  key_name                    = var.key_pair_name
  vpc_security_group_ids      = [aws_security_group.windows_primary.id]
  subnet_id                   = aws_subnet.primary_public.id
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile.name
  associate_public_ip_address = true

  user_data = local.windows_user_data

  root_block_device {
    volume_type = "gp3"
    volume_size = 50
    encrypted   = true

    tags = {
      Name = "${var.project_name}-primary-root-volume"
    }
  }

  # Additional data volume
  ebs_block_device {
    device_name = "/dev/xvdf"
    volume_type = "gp3"
    volume_size = 100
    encrypted   = true

    tags = {
      Name = "${var.project_name}-primary-data-volume"
    }
  }

  tags = {
    Name        = "${var.project_name}-windows-primary"
    Environment = var.environment
    Role        = "primary-server"
    DRSEnabled  = "true"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Secondary Windows EC2 Instance (for staging area)
resource "aws_instance" "windows_secondary" {
  provider                    = aws.secondary
  ami                         = data.aws_ami.windows_secondary.id
  instance_type               = var.instance_type
  key_name                    = var.key_pair_name
  vpc_security_group_ids      = [aws_security_group.windows_secondary.id]
  subnet_id                   = aws_subnet.secondary_public.id
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile.name
  associate_public_ip_address = true

  user_data = local.windows_user_data

  root_block_device {
    volume_type = "gp3"
    volume_size = 50
    encrypted   = true

    tags = {
      Name = "${var.project_name}-secondary-root-volume"
    }
  }

  # Additional data volume
  ebs_block_device {
    device_name = "/dev/xvdf"
    volume_type = "gp3"
    volume_size = 100
    encrypted   = true

    tags = {
      Name = "${var.project_name}-secondary-data-volume"
    }
  }

  tags = {
    Name        = "${var.project_name}-windows-secondary"
    Environment = var.environment
    Role        = "secondary-server"
    DRSStaging  = "true"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Elastic IP for primary instance
resource "aws_eip" "primary" {
  provider = aws.primary
  instance = aws_instance.windows_primary.id
  domain   = "vpc"

  tags = {
    Name        = "${var.project_name}-eip-primary"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.primary]
}

# Elastic IP for secondary instance
resource "aws_eip" "secondary" {
  provider = aws.secondary
  instance = aws_instance.windows_secondary.id
  domain   = "vpc"

  tags = {
    Name        = "${var.project_name}-eip-secondary"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.secondary]
}