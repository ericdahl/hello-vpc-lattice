resource "aws_vpclattice_target_group" "hello" {
  name = "hello-targets"
  type = "IP"

  config {
    port             = 80
    protocol         = "HTTP"
    protocol_version = "HTTP1"
    vpc_identifier   = aws_vpc.server_hello.id

    health_check {
      enabled                       = true
      healthy_threshold_count       = 2
      health_check_interval_seconds = 30
      path                          = "/"
      port                          = 80
      protocol                      = "HTTP"
      protocol_version              = "HTTP1"
      health_check_timeout_seconds  = 5
      unhealthy_threshold_count     = 2

      matcher {
        value = "200"
      }
    }
  }

  tags = {
    Name = "hello-target-group"
  }
}


resource "aws_vpclattice_service" "hello" {
  name      = "hello-service"
  auth_type = "AWS_IAM"

  tags = {
    Name = "hello-lattice-service"
  }
}

resource "aws_vpclattice_service_network_service_association" "hello" {
  service_identifier         = aws_vpclattice_service.hello.id
  service_network_identifier = aws_vpclattice_service_network.demo.id

  tags = {
    Name = "hello-service-association"
  }
}

resource "aws_vpclattice_listener" "hello" {
  name               = "hello-listener"
  protocol           = "HTTPS"
  service_identifier = aws_vpclattice_service.hello.id

  default_action {
    forward {
      target_groups {
        target_group_identifier = aws_vpclattice_target_group.hello.id
      }
    }
  }
}

resource "aws_vpclattice_listener_rule" "hello" {
  name                = "hello-rule"
  listener_identifier = aws_vpclattice_listener.hello.listener_id
  service_identifier  = aws_vpclattice_service.hello.id
  priority            = 100

  match {
    http_match {
      path_match {
        case_sensitive = false
        match {
          prefix = "/"
        }
      }
    }
  }

  action {
    forward {
      target_groups {
        target_group_identifier = aws_vpclattice_target_group.hello.id
      }
    }
  }
}