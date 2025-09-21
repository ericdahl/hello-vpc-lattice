resource "aws_vpclattice_service_network" "demo" {
  name      = "demo-svnet"
  auth_type = "AWS_IAM"

  tags = {
    Name = "demo-service-network"
  }
}

resource "aws_vpclattice_service_network_vpc_association" "client" {
  vpc_identifier             = aws_vpc.client.id
  service_network_identifier = aws_vpclattice_service_network.demo.id

  tags = {
    Name = "client-vpc-association"
  }
}

resource "aws_vpclattice_service_network_vpc_association" "server_hello" {
  vpc_identifier             = aws_vpc.server_hello.id
  service_network_identifier = aws_vpclattice_service_network.demo.id

  tags = {
    Name = "server-hello-vpc-association"
  }
}

resource "aws_vpclattice_service_network_vpc_association" "server_goodbye" {
  vpc_identifier             = aws_vpc.server_goodbye.id
  service_network_identifier = aws_vpclattice_service_network.demo.id

  tags = {
    Name = "server-goodbye-vpc-association"
  }
}

resource "aws_vpclattice_auth_policy" "demo" {
  resource_identifier = aws_vpclattice_service_network.demo.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAllVPCs"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "vpc-lattice-svcs:Invoke"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "vpc-lattice-svcs:SourceVpc" = [
              aws_vpc.client.id,
              aws_vpc.server_hello.id,
              aws_vpc.server_goodbye.id
            ]
          }
        }
      }
    ]
  })
}

resource "aws_vpclattice_auth_policy" "hello_service" {
  resource_identifier = aws_vpclattice_service.hello.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowClientVPC"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "vpc-lattice-svcs:Invoke"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "vpc-lattice-svcs:SourceVpc" = aws_vpc.client.id
          }
        }
      }
    ]
  })
}