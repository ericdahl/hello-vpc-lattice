resource "aws_iam_role" "ec2_untrusted_role" {
  name = "ec2-untrusted-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "untrusted_ssm" {
  role       = aws_iam_role.ec2_untrusted_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "untrusted_vpc_lattice_invoke" {
  statement {
    effect = "Allow"
    actions = [
      "vpc-lattice-svcs:Invoke"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "untrusted_vpc_lattice_invoke" {
  name   = "vpc-lattice-invoke"
  role   = aws_iam_role.ec2_untrusted_role.id
  policy = data.aws_iam_policy_document.untrusted_vpc_lattice_invoke.json
}

resource "aws_iam_instance_profile" "ec2_untrusted_profile" {
  name = "ec2-untrusted-profile"
  role = aws_iam_role.ec2_untrusted_role.name
}

resource "aws_security_group" "ec2_client_untrusted" {
  name_prefix = "ec2-client-untrusted-"
  vpc_id      = aws_vpc.client_untrusted.id

  tags = {
    Name = "ec2-client-untrusted-sg"
  }
}

resource "aws_vpc_security_group_egress_rule" "ec2_client_untrusted_egress" {
  security_group_id = aws_security_group.ec2_client_untrusted.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_instance" "client_untrusted" {
  ami                    = data.aws_ssm_parameter.amazon_linux_2023.value
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.client_untrusted_public_1.id
  vpc_security_group_ids = [aws_security_group.ec2_client_untrusted.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_untrusted_profile.name

  user_data_base64 = base64encode(<<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y nc valkey python3-pip
    pip3 install boto3 botocore requests

    cat > /home/ec2-user/test.py << 'PYTHON_SCRIPT'
    #!/usr/bin/env python3
    import sys
    from botocore import crt
    import requests
    from botocore.awsrequest import AWSRequest
    import botocore.session

    if len(sys.argv) < 2:
        print("Usage: test.py <endpoint>")
        sys.exit(1)

    endpoint = sys.argv[1]

    session = botocore.session.Session()
    signer = crt.auth.CrtSigV4Auth(session.get_credentials(), 'vpc-lattice-svcs', 'us-east-1')

    headers = {'x-amz-content-sha256': 'UNSIGNED-PAYLOAD'}

    request = AWSRequest(method='GET', url=endpoint, headers=headers)
    request.context["payload_signing_enabled"] = False
    signer.add_auth(request)

    response = requests.get(request.url, headers=dict(request.headers))
    print(response.text)
    PYTHON_SCRIPT

    chmod +x /home/ec2-user/test.py
    chown ec2-user:ec2-user /home/ec2-user/test.py
    EOF
  )

  tags = {
    Name = "vpc-lattice-client-untrusted"
  }
}

output "ec2_untrusted_instance_id" {
  value = aws_instance.client_untrusted.id
}

output "ec2_untrusted_instance_arn" {
  value = aws_instance.client_untrusted.arn
}
