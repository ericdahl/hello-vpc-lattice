output "hello_service_dns" {
  description = "DNS name for the hello service"
  value       = aws_vpclattice_service.hello.dns_entry[0].domain_name
}

output "goodbye_service_dns" {
  description = "DNS name for the goodbye service"
  value       = aws_vpclattice_service.goodbye.dns_entry[0].domain_name
}

output "test_commands" {
  description = "Commands to test the services from the EC2 client"
  value = {
    hello_service   = "curl https://${aws_vpclattice_service.hello.dns_entry[0].domain_name}/hello"
    goodbye_service = "curl https://${aws_vpclattice_service.goodbye.dns_entry[0].domain_name}/goodbye"
  }
}

output "ec2_instance_id" {
  description = "EC2 client instance ID for Session Manager connection"
  value       = aws_instance.client.id
}