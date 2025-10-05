data "aws_ssm_parameter" "ecs_al2023_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended"
}

resource "aws_ecs_cluster" "httpbin" {
  name = "httpbin"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ecs_httpbin_lattice_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_httpbin_lattice" {
  name               = "ecs-httpbin-lattice"
  assume_role_policy = data.aws_iam_policy_document.ecs_httpbin_lattice_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_httpbin_lattice_policy" {
  role       = aws_iam_role.ecs_httpbin_lattice.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECSInfrastructureRolePolicyForVpcLattice"
}

resource "aws_iam_role" "ecs_instance" {
  name               = "ecs-instance-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role_policy" {
  role       = aws_iam_role.ecs_instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs_instance_ssm" {
  role       = aws_iam_role.ecs_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ecs_instance" {
  name = "ecs-instance-profile"
  role = aws_iam_role.ecs_instance.name
}

resource "aws_security_group" "ecs_httpbin_instance" {
  name_prefix = "ecs-httpbin-instance-"
  vpc_id      = aws_vpc.server_httpbin.id

  tags = {
    Name = "ecs-httpbin-instance-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ecs_httpbin_instance_http" {
  security_group_id = aws_security_group.ecs_httpbin_instance.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "ecs_httpbin_instance_egress" {
  security_group_id = aws_security_group.ecs_httpbin_instance.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_launch_template" "ecs_httpbin" {
  name_prefix   = "ecs-httpbin-"
  image_id      = jsondecode(data.aws_ssm_parameter.ecs_al2023_ami.value)["image_id"]
  instance_type = "t3.medium"

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance.name
  }

  vpc_security_group_ids = [aws_security_group.ecs_httpbin_instance.id]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              echo ECS_CLUSTER=${aws_ecs_cluster.httpbin.name} >> /etc/ecs/ecs.config
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "ecs-httpbin-instance"
    }
  }
}

resource "aws_autoscaling_group" "ecs_httpbin" {
  name                = "ecs-httpbin-asg"
  vpc_zone_identifier = [aws_subnet.server_httpbin_public_1.id, aws_subnet.server_httpbin_public_2.id]
  desired_capacity    = 2
  min_size            = 2
  max_size            = 2

  launch_template {
    id      = aws_launch_template.ecs_httpbin.id
    version = aws_launch_template.ecs_httpbin.latest_version
  }

  tag {
    key                 = "Name"
    value               = "ecs-httpbin-asg"
    propagate_at_launch = false
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = "true"
    propagate_at_launch = true
  }
}

resource "aws_ecs_capacity_provider" "httpbin" {
  name = "httpbin-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs_httpbin.arn

    managed_scaling {
      status = "DISABLED"
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "httpbin" {
  cluster_name       = aws_ecs_cluster.httpbin.name
  capacity_providers = [aws_ecs_capacity_provider.httpbin.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.httpbin.name
    weight            = 100
  }
}

resource "aws_ecs_task_definition" "httpbin" {
  family             = "httpbin-task"
  network_mode       = "bridge"
  execution_role_arn = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name              = "httpbin"
      image             = "kennethreitz/httpbin"
      memory            = 512
      memoryReservation = 256
      portMappings = [
        {
          name          = "httpbin"
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.httpbin.name
          "awslogs-region"        = data.aws_region.current.id
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_cloudwatch_log_group" "httpbin" {
  name              = "/ecs/httpbin-task"
  retention_in_days = 7
}

resource "aws_ecs_service" "httpbin" {
  name            = "httpbin"
  cluster         = aws_ecs_cluster.httpbin.id
  task_definition = aws_ecs_task_definition.httpbin.arn
  desired_count   = 4
  launch_type     = "EC2"

  vpc_lattice_configurations {
    role_arn         = aws_iam_role.ecs_httpbin_lattice.arn
    target_group_arn = aws_vpclattice_target_group.httpbin.arn
    port_name        = "httpbin"
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution_role_policy,
    aws_iam_role_policy_attachment.ecs_httpbin_lattice_policy,
    aws_autoscaling_group.ecs_httpbin
  ]
}
