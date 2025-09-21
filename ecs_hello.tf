resource "aws_ecs_cluster" "hello" {
  name = "hello-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_iam_role" "ecs_task_execution" {
  name = "ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "ecs_hello_lattice_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_hello_lattice" {
  name               = "ecs-hello-lattice"
  assume_role_policy = data.aws_iam_policy_document.ecs_hello_lattice_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_hello_lattice_policy" {
  role       = aws_iam_role.ecs_hello_lattice.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECSInfrastructureRolePolicyForVpcLattice"
}

resource "aws_security_group" "ecs_hello" {
  name_prefix = "ecs-hello-"
  vpc_id      = aws_vpc.server_hello.id

  tags = {
    Name = "ecs-hello-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ecs_hello_http" {
  security_group_id = aws_security_group.ecs_hello.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "ecs_hello_egress" {
  security_group_id = aws_security_group.ecs_hello.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_ecs_task_definition" "hello" {
  family                   = "hello-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name  = "nginx"
      image = "nginx:latest"
      portMappings = [
        {
          name          = "nginx"
          containerPort = 80
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.hello.name
          "awslogs-region"        = data.aws_region.current.id
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_cloudwatch_log_group" "hello" {
  name              = "/ecs/hello-task"
  retention_in_days = 7
}

resource "aws_ecs_service" "hello" {
  name            = "hello-service"
  cluster         = aws_ecs_cluster.hello.id
  task_definition = aws_ecs_task_definition.hello.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.server_hello_public_1.id, aws_subnet.server_hello_public_2.id]
    security_groups  = [aws_security_group.ecs_hello.id]
    assign_public_ip = true
  }

  vpc_lattice_configurations {
    role_arn         = aws_iam_role.ecs_hello_lattice.arn
    target_group_arn = aws_vpclattice_target_group.hello.arn
    port_name        = "nginx"
  }
}