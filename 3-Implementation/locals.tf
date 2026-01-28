locals {
  project = "phase_3"
  ami_id  = "ubuntu"
  
  # Create a map from az_index to public subnet key for NAT gateway routing
  az_to_public_subnet = {
    for k, v in var.public_subnets : v.az_index => k
  }
}
