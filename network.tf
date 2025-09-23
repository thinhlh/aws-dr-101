data "aws_vpc" "main_vpc" {
  id = "vpc-0a02ccf6024dd1051"

  filter {
    name   = "tag:Project"
    values = ["drs"]
  }
}

# Subnet (private)
resource "aws_subnet" "project_subnet_private_us_east_1" {
  for_each = toset(var.azs)
  vpc_id   = data.aws_vpc.main_vpc.id

  tags = {
    Name = "drs-project-subnet-private-${each.value}"
  }

  cidr_block              = cidrsubnet(data.aws_vpc.main_vpc.cidr_block, 4, index(var.azs, each.value) * 2 + 2) # First 2 subnets are already taken
  availability_zone       = each.value
  map_public_ip_on_launch = false
}

resource "aws_subnet" "project_subnet_public_us_east_1" {
  for_each = toset(var.azs)
  vpc_id   = data.aws_vpc.main_vpc.id

  tags = {
    Name = "drs-project-subnet-public-${each.value}"
  }

  cidr_block              = cidrsubnet(data.aws_vpc.main_vpc.cidr_block, 4, index(var.azs, each.value) * 2 + 3) # First 2 subnets are already taken
  availability_zone       = each.value
  map_public_ip_on_launch = true
}


resource "aws_security_group" "windows_sg" {
  name   = "drs-windows-sg"
  vpc_id = data.aws_vpc.main_vpc.id

  # Allow all traffic within the VPC
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.main_vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "replication_sg" {
  name   = "drs-replication-sg"
  vpc_id = data.aws_vpc.main_vpc.id

  # Allow all traffic within the VPC
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.main_vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_nat_gateways" "project_nat_gw" {
  vpc_id = data.aws_vpc.main_vpc.id
}

# Create route tables based on the number of NAT gateways
resource "aws_route_table" "project_private_rt" {
  for_each = toset(var.azs)
  vpc_id   = data.aws_vpc.main_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = data.aws_nat_gateways.project_nat_gw.ids[index(var.azs, each.value)]
  }
  tags = {
    Name = "drs-private-rt-${index(var.azs, each.value)}"
  }
}

resource "aws_route_table_association" "project_rt_private_assoc" {
  for_each       = toset(var.azs)
  subnet_id      = aws_subnet.project_subnet_private_us_east_1[each.value].id
  route_table_id = aws_route_table.project_private_rt[each.value].id
}
