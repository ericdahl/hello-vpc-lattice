resource "aws_vpc" "client_untrusted" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "vpc-client-untrusted"
  }
}

resource "aws_internet_gateway" "client_untrusted" {
  vpc_id = aws_vpc.client_untrusted.id

  tags = {
    Name = "vpc-client-untrusted-igw"
  }
}

resource "aws_subnet" "client_untrusted_public_1" {
  vpc_id                  = aws_vpc.client_untrusted.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "vpc-client-untrusted-public-1"
  }
}

resource "aws_subnet" "client_untrusted_public_2" {
  vpc_id                  = aws_vpc.client_untrusted.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "vpc-client-untrusted-public-2"
  }
}

resource "aws_route_table" "client_untrusted_public" {
  vpc_id = aws_vpc.client_untrusted.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.client_untrusted.id
  }

  tags = {
    Name = "vpc-client-untrusted-public-rt"
  }
}

resource "aws_route_table_association" "client_untrusted_public_1" {
  subnet_id      = aws_subnet.client_untrusted_public_1.id
  route_table_id = aws_route_table.client_untrusted_public.id
}

resource "aws_route_table_association" "client_untrusted_public_2" {
  subnet_id      = aws_subnet.client_untrusted_public_2.id
  route_table_id = aws_route_table.client_untrusted_public.id
}
