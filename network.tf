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

# data "aws_eip" "project_eip_us_east_1c" {
#   filter {
#     name   = "tag:Project"
#     values = ["drs"]
#   }
# }

# resource "aws_nat_gateway" "drs_nat_gw_us_east_1c" {
#   allocation_id = data.aws_eip.project_eip_us_east_1c.id
#   subnet_id     = aws_subnet.project_subnet_public_us_east_1["us-east-1c"].id

#   tags = {
#     Name = "drs-nat-gw-us-east-1c"
#   }
# }

data "aws_nat_gateways" "project_nat_gws" {
  vpc_id = data.aws_vpc.main_vpc.id
}

locals {
  az_nat_gw = {
    # for az in var.azs : az => element(concat(data.aws_nat_gateways.project_nat_gws.ids, [aws_nat_gateway.drs_nat_gw_us_east_1c.id]), index(var.azs, az))
    for az in var.azs : az => element(data.aws_nat_gateways.project_nat_gws.ids, index(var.azs, az))
  }
}

resource "aws_route_table" "project_private_rt" {
  # depends_on = [aws_nat_gateway.drs_nat_gw_us_east_1c]
  for_each = toset(var.azs)
  vpc_id   = data.aws_vpc.main_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = local.az_nat_gw[each.value]
  }
  tags = {
    Name = "drs-private-rt-${each.value}"
  }
}

resource "aws_route_table_association" "project_rt_private_assoc" {
  for_each       = local.az_nat_gw
  subnet_id      = aws_subnet.project_subnet_private_us_east_1[each.key].id
  route_table_id = aws_route_table.project_private_rt[each.key].id
}


resource "aws_network_interface" "eni_private_us_east_1" {
  for_each = aws_subnet.project_subnet_private_us_east_1

  subnet_id         = each.value.id
  private_ips_count = 1
  security_groups   = [aws_security_group.windows_sg.id]
}