# Security Groups for Windows EC2 instances

# Primary Region Security Group
resource "aws_security_group" "windows_primary" {
  provider    = aws.primary
  name        = "${var.project_name}-windows-sg-primary"
  description = "Security group for Windows EC2 instances in primary region"
  vpc_id      = aws_vpc.primary.id

  # RDP access
  ingress {
    description = "RDP"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # HTTP access
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # HTTPS access
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # WinRM access for remote management
  ingress {
    description = "WinRM"
    from_port   = 5985
    to_port     = 5986
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # DRS agent communication
  ingress {
    description = "DRS Agent"
    from_port   = 1500
    to_port     = 1500
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-windows-sg-primary"
    Environment = var.environment
  }
}

# Secondary Region Security Group
resource "aws_security_group" "windows_secondary" {
  provider    = aws.secondary
  name        = "${var.project_name}-windows-sg-secondary"
  description = "Security group for Windows EC2 instances in secondary region"
  vpc_id      = aws_vpc.secondary.id

  # RDP access
  ingress {
    description = "RDP"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # HTTP access
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # HTTPS access
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # WinRM access for remote management
  ingress {
    description = "WinRM"
    from_port   = 5985
    to_port     = 5986
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # DRS staging area communication
  ingress {
    description = "DRS Staging"
    from_port   = 1500
    to_port     = 1500
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-windows-sg-secondary"
    Environment = var.environment
  }
}

# DRS Replication Security Group (Primary Region)
resource "aws_security_group" "drs_replication" {
  provider    = aws.primary
  name        = "${var.project_name}-drs-replication-sg"
  description = "Security group for DRS replication servers"
  vpc_id      = aws_vpc.primary.id

  # DRS replication traffic
  ingress {
    description = "DRS Replication"
    from_port   = 1500
    to_port     = 1500
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_primary, var.vpc_cidr_secondary]
  }

  # HTTPS for DRS console
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-drs-replication-sg"
    Environment = var.environment
  }
}