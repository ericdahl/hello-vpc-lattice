output "random_service_dns" {
  description = "DNS name for the random service (forwards 50/50 to hello and goodbye)"
  value       = aws_vpclattice_service.random.dns_entry[0].domain_name
}

output "test_commands" {
  description = "Commands to test the random service from the EC2 client"
  value = {
    random_service = "curl https://${aws_vpclattice_service.random.dns_entry[0].domain_name}/"
  }
}

output "ec2_instance_id" {
  description = "EC2 client instance ID for Session Manager connection"
  value       = aws_instance.client.id
}