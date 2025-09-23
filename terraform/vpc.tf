# VPC Configuration for Primary and Secondary Regions

# Primary Region VPC
resource "aws_vpc" "primary" {
  provider             = aws.primary
  cidr_block           = var.vpc_cidr_primary
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-vpc-primary"
    Environment = var.environment
    Region      = var.primary_region
  }
}

# Primary Region Internet Gateway
resource "aws_internet_gateway" "primary" {
  provider = aws.primary
  vpc_id   = aws_vpc.primary.id

  tags = {
    Name        = "${var.project_name}-igw-primary"
    Environment = var.environment
  }
}

# Primary Region Public Subnet
resource "aws_subnet" "primary_public" {
  provider                = aws.primary
  vpc_id                  = aws_vpc.primary.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.primary.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-subnet-public-primary"
    Environment = var.environment
  }
}

# Primary Region Private Subnet
resource "aws_subnet" "primary_private" {
  provider          = aws.primary
  vpc_id            = aws_vpc.primary.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.primary.names[1]

  tags = {
    Name        = "${var.project_name}-subnet-private-primary"
    Environment = var.environment
  }
}

# Primary Region Route Table for Public Subnet
resource "aws_route_table" "primary_public" {
  provider = aws.primary
  vpc_id   = aws_vpc.primary.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.primary.id
  }

  tags = {
    Name        = "${var.project_name}-rt-public-primary"
    Environment = var.environment
  }
}

# Primary Region Route Table Association
resource "aws_route_table_association" "primary_public" {
  provider       = aws.primary
  subnet_id      = aws_subnet.primary_public.id
  route_table_id = aws_route_table.primary_public.id
}

# Secondary Region VPC
resource "aws_vpc" "secondary" {
  provider             = aws.secondary
  cidr_block           = var.vpc_cidr_secondary
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-vpc-secondary"
    Environment = var.environment
    Region      = var.secondary_region
  }
}

# Secondary Region Internet Gateway
resource "aws_internet_gateway" "secondary" {
  provider = aws.secondary
  vpc_id   = aws_vpc.secondary.id

  tags = {
    Name        = "${var.project_name}-igw-secondary"
    Environment = var.environment
  }
}

# Secondary Region Public Subnet
resource "aws_subnet" "secondary_public" {
  provider                = aws.secondary
  vpc_id                  = aws_vpc.secondary.id
  cidr_block              = "10.1.1.0/24"
  availability_zone       = data.aws_availability_zones.secondary.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-subnet-public-secondary"
    Environment = var.environment
  }
}

# Secondary Region Private Subnet
resource "aws_subnet" "secondary_private" {
  provider          = aws.secondary
  vpc_id            = aws_vpc.secondary.id
  cidr_block        = "10.1.2.0/24"
  availability_zone = data.aws_availability_zones.secondary.names[1]

  tags = {
    Name        = "${var.project_name}-subnet-private-secondary"
    Environment = var.environment
  }
}

# Secondary Region Route Table for Public Subnet
resource "aws_route_table" "secondary_public" {
  provider = aws.secondary
  vpc_id   = aws_vpc.secondary.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.secondary.id
  }

  tags = {
    Name        = "${var.project_name}-rt-public-secondary"
    Environment = var.environment
  }
}

# Secondary Region Route Table Association
resource "aws_route_table_association" "secondary_public" {
  provider       = aws.secondary
  subnet_id      = aws_subnet.secondary_public.id
  route_table_id = aws_route_table.secondary_public.id
}