resource "aws_vpc" "client" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "vpc-client"
  }
}

resource "aws_internet_gateway" "client" {
  vpc_id = aws_vpc.client.id

  tags = {
    Name = "vpc-client-igw"
  }
}

resource "aws_subnet" "client_public_1" {
  vpc_id                  = aws_vpc.client.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "vpc-client-public-1"
  }
}

resource "aws_subnet" "client_public_2" {
  vpc_id                  = aws_vpc.client.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "vpc-client-public-2"
  }
}

resource "aws_route_table" "client_public" {
  vpc_id = aws_vpc.client.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.client.id
  }

  tags = {
    Name = "vpc-client-public-rt"
  }
}

resource "aws_route_table_association" "client_public_1" {
  subnet_id      = aws_subnet.client_public_1.id
  route_table_id = aws_route_table.client_public.id
}

resource "aws_route_table_association" "client_public_2" {
  subnet_id      = aws_subnet.client_public_2.id
  route_table_id = aws_route_table.client_public.id
}
