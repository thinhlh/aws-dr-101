resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.16.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

# Subnet (private)
resource "aws_subnet" "project_subnet_private_us_east_1" {
  for_each = toset(var.azs)
  vpc_id   = aws_vpc.main_vpc.id

  tags = {
    Name = "project-subnet-private-${each.value}"
  }

  cidr_block        = cidrsubnet(aws_vpc.main_vpc.cidr_block, 4, index(var.azs, each.value) + 2) # As we already have 0 and 1 used
  availability_zone = each.value
}


resource "aws_security_group" "windows_sg" {
  name   = "windows-sg"
  vpc_id = aws_vpc.main_vpc.id

  # Allow all traffic within the VPC
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.main_vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

