provider "aws" {
  region = "ap-south-1"
}

# ---------------------
# VPC
# ---------------------
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "my-vpc"
  }
}

# ---------------------
# Internet Gateway
# ---------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "vpc-igw"
  }
}

# ---------------------
# Public Subnets (2)
# ---------------------
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-2"
  }
}

# ---------------------
# Private Subnets (2)
# ---------------------
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "private-subnet-1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "private-subnet-2"
  }
}

# ---------------------
# Database Subnets (2)
# ---------------------
resource "aws_subnet" "db_subnet_1" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "db-subnet-1"
  }
}

resource "aws_subnet" "db_subnet_2" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.6.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "db-subnet-2"
  }
}

# ---------------------
# Elastic IP for NAT
# ---------------------
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "nat-eip"
  }
}

# ---------------------
# NAT Gateway (in Public Subnet 1)
# ---------------------
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id

  tags = {
    Name = "nat-gateway"
  }

  depends_on = [aws_internet_gateway.igw]
}

# ---------------------
# Route Tables
# ---------------------

# Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

# Private Route Table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "private-rt"
  }
}

# DB Route Table (no internet access)
resource "aws_route_table" "db_rt" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "db-rt"
  }
}

# ---------------------
# Route Table Associations
# ---------------------

# Public
resource "aws_route_table_association" "public_assoc_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

# Private
resource "aws_route_table_association" "private_assoc_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_assoc_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt.id
}

# DB
resource "aws_route_table_association" "db_assoc_1" {
  subnet_id      = aws_subnet.db_subnet_1.id
  route_table_id = aws_route_table.db_rt.id
}

resource "aws_route_table_association" "db_assoc_2" {
  subnet_id      = aws_subnet.db_subnet_2.id
  route_table_id = aws_route_table.db_rt.id
}

# ---------------------
# Outputs
# ---------------------
output "vpc_id" {
  value = aws_vpc.main_vpc.id
}

output "public_subnets" {
  value = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
}

output "private_subnets" {
  value = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
}

output "db_subnets" {
  value = [aws_subnet.db_subnet_1.id, aws_subnet.db_subnet_2.id]
}
