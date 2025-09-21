resource "aws_vpc" "server_goodbye" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "vpc-server-goodbye"
  }
}

resource "aws_internet_gateway" "server_goodbye" {
  vpc_id = aws_vpc.server_goodbye.id

  tags = {
    Name = "vpc-server-goodbye-igw"
  }
}

resource "aws_subnet" "server_goodbye_public_1" {
  vpc_id                  = aws_vpc.server_goodbye.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "vpc-server-goodbye-public-1"
  }
}

resource "aws_subnet" "server_goodbye_public_2" {
  vpc_id                  = aws_vpc.server_goodbye.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "vpc-server-goodbye-public-2"
  }
}

resource "aws_route_table" "server_goodbye_public" {
  vpc_id = aws_vpc.server_goodbye.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.server_goodbye.id
  }

  tags = {
    Name = "vpc-server-goodbye-public-rt"
  }
}

resource "aws_route_table_association" "server_goodbye_public_1" {
  subnet_id      = aws_subnet.server_goodbye_public_1.id
  route_table_id = aws_route_table.server_goodbye_public.id
}

resource "aws_route_table_association" "server_goodbye_public_2" {
  subnet_id      = aws_subnet.server_goodbye_public_2.id
  route_table_id = aws_route_table.server_goodbye_public.id
}