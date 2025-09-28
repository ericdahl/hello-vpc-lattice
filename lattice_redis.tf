resource "aws_vpclattice_resource_gateway" "redis" {
  name       = "redis"
  vpc_id     = aws_vpc.server_redis.id
  subnet_ids = [aws_subnet.server_redis_public_1.id, aws_subnet.server_redis_public_2.id]

  tags = {
    Environment = "redis"
  }
}

resource "aws_vpclattice_resource_configuration" "redis" {
  name = "redis"

  resource_gateway_identifier = aws_vpclattice_resource_gateway.redis.id

  port_ranges = [aws_elasticache_serverless_cache.hello_cache.endpoint[0].port]
  protocol    = "TCP"

  resource_configuration_definition {

    dns_resource {
      domain_name     = aws_elasticache_serverless_cache.hello_cache.endpoint[0].address
      ip_address_type = "IPV4"
    }
  }
}

resource "aws_vpclattice_service_network_resource_association" "redis" {
  resource_configuration_identifier = aws_vpclattice_resource_configuration.redis.id
  service_network_identifier        = aws_vpclattice_service_network.demo.id

  tags = {
    Name = "redis"
  }
}

output "redis" {
  value = aws_vpclattice_service_network_resource_association.redis.dns_entry[0].domain_name
}