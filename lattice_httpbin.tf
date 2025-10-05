resource "aws_vpclattice_target_group" "httpbin" {
  name = "httpbin-targets"
  type = "IP"

  config {
    port             = 80
    protocol         = "HTTP"
    protocol_version = "HTTP1"
    vpc_identifier   = aws_vpc.server_httpbin.id

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
    Name = "httpbin-target-group"
  }
}
