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

data "aws_iam_policy_document" "demo_service_network_auth" {
  statement {
    sid    = "AllowAllVPCs"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = ["vpc-lattice-svcs:Invoke"]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "vpc-lattice-svcs:SourceVpc"
      values = [
        aws_vpc.client.id,
        aws_vpc.server_hello.id,
        aws_vpc.server_goodbye.id
      ]
    }
  }
}

data "aws_iam_policy_document" "hello_service_auth" {
  statement {
    sid    = "AllowClientVPC"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = ["vpc-lattice-svcs:Invoke"]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "vpc-lattice-svcs:SourceVpc"
      values   = [aws_vpc.client.id]
    }
  }
}

resource "aws_vpclattice_auth_policy" "demo" {
  resource_identifier = aws_vpclattice_service_network.demo.arn
  policy              = data.aws_iam_policy_document.demo_service_network_auth.json
}

resource "aws_vpclattice_auth_policy" "hello_service" {
  resource_identifier = aws_vpclattice_service.hello.arn
  policy              = data.aws_iam_policy_document.hello_service_auth.json
}