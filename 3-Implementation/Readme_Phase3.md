# Phase 3: Multi-Tier AWS Infrastructure with Terraform

## Project Overview

Phase 3 represents a comprehensive implementation of a production-ready, multi-tier AWS infrastructure using Terraform. This project builds upon foundational networking concepts to create a highly available architecture spanning multiple availability zones with both public and private subnets, complete with web servers, application servers, and proper network routing.

## Architecture Summary

This infrastructure creates:
- **1 VPC** with CIDR block 10.0.0.0/16
- **3 Public Subnets** across different availability zones (10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24)
- **3 Private Subnets** across different availability zones (10.0.11.0/24, 10.0.12.0/24, 10.0.13.0/24)
- **3 Web Servers** (EC2 instances) in public subnets running Nginx
- **3 Application Servers** (EC2 instances) in private subnets
- **3 NAT Gateways** (one per availability zone for high availability)
- **3 Elastic IPs** for the NAT Gateways
- **1 Internet Gateway** for public internet access
- **Route tables** configured for public and private subnet traffic routing
- **Security Groups** for web and application tier access control

## Key Learning Objectives

### 1. Multi-Tier Architecture Design
Understanding the separation of concerns between web tier (public) and application tier (private) for improved security and scalability.

### 2. High Availability with Multiple Availability Zones
Distributing resources across three availability zones ensures resilience against zone-level failures. Each availability zone is independent, providing fault tolerance.

### 3. Advanced Terraform Concepts

#### for_each Meta-Argument
This project extensively uses `for_each` to create multiple similar resources from map variables:

```hcl
resource "aws_subnet" "public" {
  for_each          = var.public_subnets
  cidr_block        = each.value.cidr_block
  vpc_id            = aws_vpc.principal.id
  availability_zone = data.aws_availability_zones.zones.names[each.value.az_index]
  # ...
}
```

**Key Insight:** `for_each` creates a map of resource instances where each key-value pair from the input map produces one instance. This is more flexible than `count` for managing infrastructure that needs to be referenced by meaningful keys.

#### Dynamic Subnet-to-AZ Mapping
The project uses `az_index` to dynamically map subnets to specific availability zones, making the configuration portable across AWS regions:

```hcl
availability_zone = data.aws_availability_zones.zones.names[each.value.az_index]
```

### 4. NAT Gateway Architecture

#### Why Multiple NAT Gateways?
Each availability zone has its own NAT Gateway to:
- Prevent cross-AZ data transfer charges
- Ensure high availability (if one AZ fails, others remain functional)
- Reduce latency by keeping traffic within the same AZ

#### NAT Gateway Routing Strategy
Private subnets route outbound traffic to the NAT Gateway in their corresponding availability zone:

```hcl
resource "aws_route_table" "private_rt" {
  for_each = aws_subnet.private
  vpc_id   = aws_vpc.principal.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[replace(each.key, "private", "public")].id
  }
}
```

**Key Technique:** The `replace()` function transforms the private subnet key to its corresponding public subnet key (e.g., "app_private-1" → "server_public-1"), enabling the correct NAT Gateway association.

### 5. User Data for Instance Configuration

User data allows automated configuration of EC2 instances at launch time. I researched how to install and configure Nginx using bash scripts in the user_data block:

```hcl
user_data = <<-EOF
            #!/bin/bash
            apt-get update
            apt-get install -y nginx
            echo "<h1>Web Server ${each.key}</h1>" > /var/www/html/index.html
            systemctl start nginx
            systemctl enable nginx
            EOF
```

**What This Does:**
1. Updates package repositories
2. Installs Nginx web server
3. Creates a custom HTML page with the server identifier
4. Starts the Nginx service
5. Enables Nginx to start automatically on boot

### 6. Data Sources

#### Availability Zones
```hcl
data "aws_availability_zones" "zones" {
  state = "available"
}
```
Dynamically retrieves available AZs in the current region, making the code portable across different AWS regions.

#### AMI Lookup
```hcl
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical's AWS account ID
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-22.04-amd64-server-*"]
  }
}
```
Always selects the latest Ubuntu 22.04 AMI, ensuring instances use current, patched images without hardcoding AMI IDs.

### 7. Variable Validation

The project implements comprehensive input validation:

```hcl
validation {
  condition     = var.server_config.root_block_device.volume_size >= 10 && var.server_config.root_block_device.volume_size <= 100
  error_message = "Volume size needs to be between 10 and 100 GB."
}

validation {
  condition     = contains(["gp3", "io2", "io3"], var.server_config.root_block_device.volume_type)
  error_message = "Volume type must be gp3, io2 or io3"
}
```

**Benefits:**
- Catches configuration errors before deployment
- Enforces organizational standards
- Provides clear error messages
- Validates CIDR blocks, instance types, and volume configurations

### 8. Security Group Strategy

#### Web Server Security Group
- **Ingress:** HTTPS (443) from anywhere, SSH (22) from specified CIDR blocks
- **Egress:** All traffic allowed (for package downloads, updates)

#### Application Server Security Group
- **Ingress:** All traffic (should be restricted to web tier in production)
- **Egress:** All traffic allowed

**Security Consideration:** In a production environment, the application security group should only allow traffic from the web security group, not from 0.0.0.0/0.

### 9. Resource Dependencies

Terraform automatically manages most dependencies, but explicit dependencies are defined where needed:

```hcl
resource "aws_nat_gateway" "main" {
  # ...
  depends_on = [aws_internet_gateway.main]
}
```

The NAT Gateway requires the Internet Gateway to exist first, even though there's no direct reference in the configuration.

### 10. Output Values with for_each

When resources are created with `for_each`, outputs must iterate over the resource map:

```hcl
output "web_server_ids" {
  description = "IDs of web servers"
  value       = { for k, v in aws_instance.web_servers : k => v.id }
}
```

This creates a map of server names to their IDs, making it easy to identify which server is which.

## File Structure

```
phase-3/
├── providers.tf        # Terraform and AWS provider configuration
├── variables.tf        # Input variable definitions with validation
├── terraform.tfvars    # Variable values
├── locals.tf           # Local values and computed data
├── data.tf             # Data sources (AZs, AMIs)
├── networking.tf       # VPC, subnets, IGW, NAT, route tables
├── security.tf         # Security groups
├── compute.tf          # EC2 instances
├── outputs.tf          # Output values
└── _terraform_lock.hcl # Provider version lock file
```

## Key Terraform Commands Used

```bash
# Initialize Terraform and download providers
terraform init

# Validate configuration files
terraform validate

# Preview changes
terraform plan

# Apply infrastructure changes
terraform apply

# View current state
terraform show

# Destroy all resources
terraform destroy
```

## Configuration Details

### Public Subnets
- Located in AZs 0, 1, and 2
- CIDR: 10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24
- Internet-routable via Internet Gateway
- Host web servers with public IPs

### Private Subnets
- Located in AZs 0, 1, and 2
- CIDR: 10.0.11.0/24, 10.0.12.0/24, 10.0.13.0/24
- Internet-routable via NAT Gateways
- Host application servers (no public IPs)

### EC2 Instance Configuration
- **Instance Type:** t3.micro (suitable for testing, free tier eligible)
- **AMI:** Latest Ubuntu 22.04 LTS
- **Root Volume:** 30 GB gp3 SSD
- **Web Servers:** Automatically install and configure Nginx

## Challenges and Solutions

### Challenge 1: Mapping Private Subnets to Correct NAT Gateways
**Problem:** Each private subnet needed to route to the NAT Gateway in its corresponding availability zone.

**Solution:** Used the `replace()` function to transform subnet naming convention from private to public, enabling correct NAT Gateway lookups:
```hcl
nat_gateway_id = aws_nat_gateway.main[replace(each.key, "private", "public")].id
```

### Challenge 2: Understanding for_each with Outputs
**Problem:** Initial attempts to reference resources created with `for_each` resulted in errors.

**Solution:** Learned that resources created with `for_each` become maps and must be accessed using for expressions in outputs:
```hcl
value = { for k, v in aws_instance.web_servers : k => v.id }
```

### Challenge 3: Automating Web Server Configuration
**Problem:** Needed a way to automatically configure Nginx on web servers without manual intervention.

**Solution:** Researched user_data scripts and bash automation to install and configure Nginx at instance launch time, including custom HTML content to identify each server.

## Best Practices Demonstrated

1. **Modular File Organization:** Separating resources by function (networking, compute, security)
2. **Variable Validation:** Preventing invalid configurations before deployment
3. **Data Sources:** Using dynamic lookups instead of hardcoded values
4. **Meaningful Naming:** Using descriptive names with project prefixes
5. **Tagging Strategy:** Consistent tagging for resource management
6. **High Availability:** Multi-AZ deployment with zone-specific NAT Gateways
7. **Security Layers:** Network segmentation with public and private tiers
8. **Documentation:** Comprehensive variable descriptions and output documentation

## Cost Optimization Considerations

**Estimated Monthly Costs (as of deployment):**
- 3 × t3.micro instances (web): ~$7.50/month (free tier eligible)
- 3 × t3.micro instances (app): ~$7.50/month (free tier eligible)
- 3 × NAT Gateways: ~$97.20/month ($0.045/hour × 3 × 730 hours)
- 3 × Elastic IPs (attached to NAT): Free
- Data transfer: Variable

**Note:** NAT Gateways are the primary cost driver. For development/testing, consider using a single NAT Gateway or NAT instances to reduce costs.

## Future Enhancements

Potential improvements in future Phases:
1. Add Users, Roles, and Permissions.
2. Add Application Load Balancer for web tier
3. Implement Auto Scaling Groups
4. Add RDS database in private subnets
5. Configure CloudWatch monitoring and alarms
6. Implement Systems Manager Session Manager for private instance access
7. Add S3 bucket for static content
8. Implement VPC Flow Logs for network monitoring
9. Add WAF (Web Application Firewall)
10. Implement proper secret management with AWS Secrets Manager

## Lessons Learned

1. **for_each is powerful for managing multiple similar resources** - More flexible than count when you need to reference resources by meaningful keys
2. **User data enables infrastructure automation** - Can configure instances at launch without manual intervention
3. **NAT Gateways provide high availability but at a cost** - Multiple NAT Gateways prevent cross-AZ charges and improve resilience
4. **Variable validation prevents deployment errors** - Catching issues early saves time and prevents failed deployments
5. **Data sources make code portable** - Using dynamic lookups instead of hardcoded values makes infrastructure code region-agnostic
6. **Proper security group configuration is critical** - Network segmentation provides defense in depth
7. **Terraform's implicit dependency management works well** - Most dependencies are handled automatically, but explicit dependencies can be specified when needed

## Conclusion

Phase 3 demonstrates a production-ready, multi-tier AWS architecture with high availability, proper security segmentation, and automated instance configuration. The project showcases advanced Terraform features including for_each loops, dynamic resource mapping, data sources, variable validation, and user data automation. This foundation provides a solid base for building more complex, scalable applications on AWS.
