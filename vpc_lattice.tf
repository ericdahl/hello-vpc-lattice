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

data "aws_iam_policy_document" "demo_service_network_auth" {
  statement {
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
      ]
    }
  }
}


data "aws_iam_policy_document" "random_service_auth" {
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


resource "aws_vpclattice_auth_policy" "random_service" {
  resource_identifier = aws_vpclattice_service.random.arn
  policy              = data.aws_iam_policy_document.random_service_auth.json
}

resource "aws_vpclattice_access_log_subscription" "service_network" {
  resource_identifier = aws_vpclattice_service_network.demo.id
  destination_arn     = aws_cloudwatch_log_group.service_network.arn
}

resource "aws_cloudwatch_log_group" "service_network" {
  name              = "lattice-service-network"
  retention_in_days = 7
}