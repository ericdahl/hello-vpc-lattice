resource "aws_elasticache_serverless_cache" "hello_cache" {
  engine = "valkey"
  name   = "hello-cache"

  cache_usage_limits {
    data_storage {
      maximum = 1
      unit    = "GB"
    }
    ecpu_per_second {
      maximum = 1000
    }
  }

  subnet_ids         = [aws_subnet.server_redis_public_1.id, aws_subnet.server_redis_public_2.id]
  security_group_ids = [aws_security_group.valkey.id]

  tags = {
    Name = "hello-cache"
  }
}

resource "aws_security_group" "valkey" {
  name_prefix = "valkey-"
  vpc_id      = aws_vpc.server_redis.id

  tags = {
    Name = "valkey-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "valkey" {
  security_group_id = aws_security_group.valkey.id
  from_port         = 6379
  to_port           = 6379
  ip_protocol       = "tcp"
  cidr_ipv4         = aws_vpc.server_redis.cidr_block
}

resource "aws_vpc_security_group_egress_rule" "valkey" {
  security_group_id = aws_security_group.valkey.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}