# Web Server Outputs
output "web_server_ids" {
  description = "IDs of web servers"
  value       = { for k, v in aws_instance.web_servers : k => v.id }
}

output "web_server_public_ips" {
  description = "Public IPs of web servers"
  value       = { for k, v in aws_instance.web_servers : k => v.public_ip }
}

# App Server Outputs
output "app_server_ids" {
  description = "IDs of app servers"
  value       = { for k, v in aws_instance.app_servers : k => v.id }
}

output "app_server_private_ips" {
  description = "Private IPs of app servers"
  value       = { for k, v in aws_instance.app_servers : k => v.private_ip }
}

# NAT Gateway Outputs
output "nat_gateway_details" {
  description = "Details of NAT Gateways"
  value = { 
    for k, v in aws_nat_gateway.main : k => {
      id                = v.id
      public_ip         = v.public_ip
      subnet_id         = v.subnet_id
      availability_zone = aws_subnet.public[k].availability_zone
      private_ip        = v.private_ip
      network_interface_id = v.network_interface_id
    }
  }
}

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value = {
    vpc_id              = aws_vpc.principal.id
    main_route_table_id = aws_vpc.principal.main_route_table_id
  }
}
