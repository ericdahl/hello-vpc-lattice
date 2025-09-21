data "aws_ssm_parameter" "amazon_linux_2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64"
}

resource "aws_iam_role" "ec2_ssm_role" {
  name = "ec2-ssm-role"

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

resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm_role.name
}

resource "aws_security_group" "ec2_client" {
  name_prefix = "ec2-client-"
  vpc_id      = aws_vpc.client.id

  tags = {
    Name = "ec2-client-sg"
  }
}

resource "aws_vpc_security_group_egress_rule" "ec2_client_egress" {
  security_group_id = aws_security_group.ec2_client.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_instance" "client" {
  ami                    = data.aws_ssm_parameter.amazon_linux_2023.value
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.client_public_1.id
  vpc_security_group_ids = [aws_security_group.ec2_client.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_ssm_profile.name

  tags = {
    Name = "vpc-lattice-client"
  }
}