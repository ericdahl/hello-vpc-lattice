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