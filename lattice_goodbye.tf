resource "aws_vpclattice_target_group" "goodbye" {
  name = "goodbye-targets"
  type = "LAMBDA"

  tags = {
    Name = "goodbye-target-group"
  }
}

resource "aws_vpclattice_target_group_attachment" "goodbye" {
  target_group_identifier = aws_vpclattice_target_group.goodbye.id

  target {
    id = aws_lambda_function.goodbye.arn
  }
}

resource "aws_lambda_permission" "lattice" {
  statement_id  = "AllowVPCLatticeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.goodbye.function_name
  principal     = "vpc-lattice.amazonaws.com"
  source_arn    = aws_vpclattice_target_group.goodbye.arn
}

resource "aws_vpclattice_service" "goodbye" {
  name      = "goodbye-service"
  auth_type = "AWS_IAM"

  tags = {
    Name = "goodbye-lattice-service"
  }
}

resource "aws_vpclattice_service_network_service_association" "goodbye" {
  service_identifier         = aws_vpclattice_service.goodbye.id
  service_network_identifier = aws_vpclattice_service_network.demo.id

  tags = {
    Name = "goodbye-service-association"
  }
}

resource "aws_vpclattice_listener" "goodbye" {
  name               = "goodbye-listener"
  protocol           = "HTTPS"
  service_identifier = aws_vpclattice_service.goodbye.id

  default_action {
    forward {
      target_groups {
        target_group_identifier = aws_vpclattice_target_group.goodbye.id
      }
    }
  }
}

resource "aws_vpclattice_listener_rule" "goodbye" {
  name                = "goodbye-rule"
  listener_identifier = aws_vpclattice_listener.goodbye.listener_id
  service_identifier  = aws_vpclattice_service.goodbye.id
  priority            = 100

  match {
    http_match {
      path_match {
        case_sensitive = false
        match {
          prefix = "/goodbye"
        }
      }
    }
  }

  action {
    forward {
      target_groups {
        target_group_identifier = aws_vpclattice_target_group.goodbye.id
      }
    }
  }
}