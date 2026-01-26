# Terraform Phase 2: Dynamic EC2 Instance Deployment

## Project Goal

Build upon Phase 1's region-agnostic subnet infrastructure by deploying EC2 instances dynamically across all created subnets, using data sources for AMIs and complex nested object variables for configuration.

## What I Learned in Phase 2

### 1. Fetching AMIs Dynamically with Data Sources

Instead of hardcoding AMI IDs (which change by region and over time), I learned to use the `aws_ami` data source to automatically fetch the latest Ubuntu AMI.

**Added to `data.tf`:**
```hcl
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical's owner ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
```

**Key insights:**
- `most_recent = true` ensures I always get the latest version
- Filters narrow down to exactly the Ubuntu version I need
- The owner ID (`099720109477`) ensures I'm getting official Canonical AMIs, not community copies
- This works across all regions - Terraform finds the correct AMI ID for whatever region I'm deploying to

### 2. Using For_Each to Deploy Instances Across Subnets

One of my main goals was to deploy one EC2 instance in each subnet I created in Phase 1. I used `for_each` to iterate over the subnets.

**In `compute.tf`:**
```hcl
resource "aws_instance" "web_servers" {
  for_each      = aws_subnet.public
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.server_config.instance_type
  subnet_id     = each.value.id
  
  # ... rest of configuration
}
```

**How this works:**
- `for_each = aws_subnet.public` iterates over all subnets created by the `aws_subnet.public` resource
- Since `aws_subnet.public` used `for_each` in Phase 1, it's a map with keys like "server_public-1", "server_public-2", etc.
- `each.key` gives me the subnet name (e.g., "server_public-1")
- `each.value.id` gives me the actual subnet ID that AWS assigned
- Each iteration creates one EC2 instance

**Result:** If I have 3 subnets, I automatically get 3 EC2 instances - one in each subnet. If I add a 4th subnet to my `terraform.tfvars`, I'll automatically get a 4th instance without changing my compute configuration.

### 3. Accessing Data Source Attributes

Initially, I tried to reference the AMI like this:
```hcl
ami = data.aws_ami.ubuntu  # ❌ Wrong
```

**What I learned:** Data sources are objects with multiple attributes. I need to specify which attribute I want:
```hcl
ami = data.aws_ami.ubuntu.id  # ✅ Correct
```

The `aws_ami` data source returns many attributes (id, name, architecture, description, etc.), but for the EC2 instance resource, I specifically need the `.id` attribute.

### 4. Designing Nested Object Variables

I wanted to configure both the instance type and root block device settings through variables. This required understanding nested object structures.

**In `variables.tf`:**
```hcl
variable "server_config" {
  type = object({
    instance_type = string
    root_block_device = object({
      volume_size = number
      volume_type = string
    })
  })
}
```

**What this structure means:**
- The outer object contains general server configuration
- `root_block_device` is itself an object nested inside the main object
- This mirrors AWS's resource structure where `root_block_device` is a nested configuration block

**In `terraform.tfvars`:**
```hcl
server_config = {
  instance_type = "t3.micro"
  root_block_device = {
    volume_size = 30
    volume_type = "gp3"
  }
}
```

### 5. Understanding Resource Blocks vs Arguments

This was a crucial distinction I learned. In Terraform resources, there are two types of configurations:

**Arguments** (simple key-value pairs):
```hcl
resource "aws_instance" "web_servers" {
  ami           = data.aws_ami.ubuntu.id      # Argument
  instance_type = var.server_config.instance_type  # Argument
  subnet_id     = each.value.id               # Argument
}
```

**Blocks** (nested configurations):
```hcl
resource "aws_instance" "web_servers" {
  # ... arguments above
  
  root_block_device {  # This is a BLOCK, not an argument
    volume_size = var.server_config.root_block_device.volume_size
    volume_type = var.server_config.root_block_device.volume_type
  }
}
```

**Key difference:**
- Arguments use `=` and appear at the resource level
- Blocks use `{ }` and contain their own set of arguments inside
- You can't assign a value directly to a block; you configure it with nested arguments

### 6. Referencing Nested Object Attributes

To access values from my nested variable structure, I had to chain the attribute references:

```hcl
var.server_config.instance_type                      # Access top-level attribute
var.server_config.root_block_device.volume_size      # Access nested attribute
var.server_config.root_block_device.volume_type      # Access another nested attribute
```

This dot notation walks through the object hierarchy.

### 7. Choosing the Right Data Types

I initially defined `volume_size` as a string:
```hcl
volume_size = string  # ❌ Wrong type
```

But AWS expects a number, so I corrected it:
```hcl
volume_size = number  # ✅ Correct type
```

**In `terraform.tfvars`:**
```hcl
root_block_device = {
  volume_size = 30      # No quotes - it's a number
  volume_type = "gp3"   # Quotes - it's a string
}
```

**Why this matters:**
- Terraform validates types before running
- Using the wrong type causes errors before you even hit AWS
- Numbers don't need quotes; strings do

### 8. Resource Naming with For_Each

My instances get automatically named based on the subnet keys:

```hcl
tags = {
  Name    = "${local.project}-${each.key}"
  Project = local.project
}
```

With subnet keys like "server_public-1", "server_public-2", "server_public-3", my instances get named:
- `phase_2-server_public-1`
- `phase_2-server_public-2`
- `phase_2-server_public-3`

This creates a clear naming convention showing which instance is in which subnet.

### 9. The Power of For_Each with Resource References

One of the most powerful patterns I learned:

```hcl
# Phase 1: Create subnets with for_each
resource "aws_subnet" "public" {
  for_each = var.public_subnets
  # ...
}

# Phase 2: Create instances using the same for_each
resource "aws_instance" "web_servers" {
  for_each = aws_subnet.public  # Reference the subnets map
  subnet_id = each.value.id
  # ...
}
```

This creates a direct 1:1 relationship between subnets and instances. The keys match automatically, ensuring "server_public-1" subnet gets instance "server_public-1".

## Complete Working Implementation

**compute.tf:**
```hcl
resource "aws_instance" "web_servers" {
  for_each      = aws_subnet.public
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.server_config.instance_type
  subnet_id     = each.value.id
  
  root_block_device {
    volume_size = var.server_config.root_block_device.volume_size
    volume_type = var.server_config.root_block_device.volume_type
  }
  
  tags = {
    Name    = "${local.project}-${each.key}"
    Project = local.project
  }
}
```

**variables.tf:**
```hcl
variable "server_config" {
  type = object({
    instance_type = string
    root_block_device = object({
      volume_size = number
      volume_type = string
    })
  })
}
```

**terraform.tfvars:**
```hcl
server_config = {
  instance_type = "t3.micro"
  root_block_device = {
    volume_size = 30
    volume_type = "gp3"
  }
}
```

## Key Takeaways

1. **Data sources keep code current** - The AMI data source automatically finds the latest Ubuntu image, so my code doesn't need updates when new AMI versions are released

2. **For_each creates scalable patterns** - By using `for_each` on both subnets and instances, I can scale from 3 to 10 subnets just by updating `terraform.tfvars`

3. **Object nesting mirrors AWS structure** - Nested objects in variables match AWS's nested configuration blocks, making the relationship intuitive

4. **Type safety prevents errors** - Using proper types (number vs string) catches configuration errors before deployment

5. **Chaining for_each creates relationships** - Using the output of one for_each as input to another creates automatic resource relationships

## Architecture Result

After running `terraform apply`, I have:
- 1 VPC (10.0.0.0/16)
- 3 public subnets across different availability zones
- 3 EC2 instances, one in each subnet
- All using the latest Ubuntu 22.04 AMI
- Custom root volumes (30GB gp3)
- Everything named and tagged consistently

And it all works in any AWS region by just changing the provider configuration!

## Next Steps

- Add security groups to control network access
- Make instance count configurable (deploy multiple instances per subnet)
- Add private subnets and NAT gateways
- Explore using `count` vs `for_each` for different scaling patterns
- Add validation to ensure volume_size is within reasonable limits