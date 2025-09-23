resource "aws_vpc" "main_vpc" {
  cidr_block           = local.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "dsr-main-vpc"
  }
}

# Subnet (private)
resource "aws_subnet" "project_subnet_private_us_east_1" {
  for_each = toset(var.azs)
  vpc_id   = aws_vpc.main_vpc.id

  tags = {
    Name = "dsr-project-subnet-private-${each.value}"
  }

  cidr_block              = cidrsubnet(aws_vpc.main_vpc.cidr_block, 4, index(var.azs, each.value) * 2 + 2) # First 2 subnets are already taken
  availability_zone       = each.value
  map_public_ip_on_launch = false
}

resource "aws_subnet" "project_subnet_public_us_east_1" {
  for_each = toset(var.azs)
  vpc_id   = aws_vpc.main_vpc.id

  tags = {
    Name = "dsr-project-subnet-public-${each.value}"
  }

  cidr_block              = cidrsubnet(aws_vpc.main_vpc.cidr_block, 4, index(var.azs, each.value) * 2 + 3) # First 2 subnets are already taken
  availability_zone       = each.value
  map_public_ip_on_launch = true
}


resource "aws_security_group" "windows_sg" {
  name   = "dsr-windows-sg"
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

resource "aws_eip" "project_nat_eip" {
  for_each = toset(var.azs)
  tags = {
    Name = "dsr-nat-eip-${each.value}"
  }
}

resource "aws_internet_gateway" "project_igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "dsr-project-igw"
  }
}

resource "aws_nat_gateway" "project_private_ngw" {
  for_each          = toset(var.azs)
  connectivity_type = "public"
  subnet_id         = aws_subnet.project_subnet_public_us_east_1[each.value].id
  allocation_id     = aws_eip.project_nat_eip[each.value].id
  tags = {
    Name = "dsr-private-ngw-${each.value}"
  }
}

resource "aws_route_table" "project_public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.project_igw.id
  }
}

resource "aws_route_table_association" "project_rt_public_assoc" {
  for_each       = toset(var.azs)
  subnet_id      = aws_subnet.project_subnet_public_us_east_1[each.value].id
  route_table_id = aws_route_table.project_public_rt.id
}

resource "aws_route_table" "project_private_rt" {
  for_each = toset(var.azs)
  vpc_id   = aws_vpc.main_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.project_private_ngw[each.value].id
  }
  tags = {
    Name = "dsr-private-rt-${each.value}"
  }
}

resource "aws_route_table_association" "project_rt_private_assoc" {
  for_each       = toset(var.azs)
  subnet_id      = aws_subnet.project_subnet_private_us_east_1[each.value].id
  route_table_id = aws_route_table.project_private_rt[each.value].id
}
