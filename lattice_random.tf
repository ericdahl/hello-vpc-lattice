resource "aws_vpclattice_service" "random" {
  name      = "random-service"
  auth_type = "AWS_IAM"

  tags = {
    Name = "random-lattice-service"
  }
}

resource "aws_vpclattice_service_network_service_association" "random" {
  service_identifier         = aws_vpclattice_service.random.id
  service_network_identifier = aws_vpclattice_service_network.demo.id

  tags = {
    Name = "random-service-association"
  }
}

resource "aws_vpclattice_listener" "random" {
  name               = "random-listener"
  protocol           = "HTTPS"
  service_identifier = aws_vpclattice_service.random.id

  default_action {
    forward {
      target_groups {
        target_group_identifier = aws_vpclattice_target_group.hello.id
        weight                  = 50
      }
      target_groups {
        target_group_identifier = aws_vpclattice_target_group.goodbye.id
        weight                  = 50
      }
    }
  }
}

resource "aws_vpclattice_access_log_subscription" "random" {
  resource_identifier = aws_vpclattice_service.random.id
  destination_arn     = aws_cloudwatch_log_group.random.arn
}

resource "aws_cloudwatch_log_group" "random" {
  name              = "lattice-service-random"
  retention_in_days = 7
}