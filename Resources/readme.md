Terraform Dynamic Availability Zones Project
Project Goal
Build a region-agnostic AWS infrastructure using Terraform that dynamically selects availability zones without hardcoding, allowing the same code to work across different AWS regions.
What I Learned
1. Using Data Sources to Fetch Availability Zones
Instead of hardcoding availability zones like "us-east-1a" which only works in one region, I learned to use the aws_availability_zones data source to dynamically fetch available AZs for any region.
Created data.tf:
hcldata "aws_availability_zones" "zones" {
  state = "available"
}
Key insight: Data sources allow you to query AWS for current information at runtime, making your infrastructure code portable across regions.
2. Understanding Data Source Structure
This was a critical learning moment. When I first tried to reference the data source, I got this error:
Error: Invalid index
The given key does not identify an element in this collection value. 
An object only supports looking up attributes by name, not by numeric index.
What I learned:

data.aws_availability_zones.zones is an object with multiple attributes
To get the list of AZ names, I need to access the .names attribute specifically
Only after accessing .names can I use numeric indexing

Correct usage:
hclavailability_zone = data.aws_availability_zones.zones.names[each.value.az_index]
This returns something like ["us-east-1a", "us-east-1b", "us-east-1c"] and I can pick by index.
3. The Limitations of terraform.tfvars
I initially tried to reference Terraform resources inside my terraform.tfvars file:
hcl# ❌ This doesn't work!
public_subnets = {
  "public-1" = {
    cidr_block = "10.0.1.0/24"
    vpc_id     = aws_vpc.principal  # Can't reference resources here!
    az_index   = 0
  }
}
What I learned:

terraform.tfvars is for values only, not Terraform expressions or resource references
Resource references like aws_vpc.principal.id belong in your .tf files, not in .tfvars
When Terraform encounters invalid syntax in tfvars, it fails to parse the file and gives a confusing "variable not set" error

Correct approach:

Keep only simple values in terraform.tfvars
Set resource relationships in your resource definitions in .tf files

4. Variable Structure Design
I designed my variable to accept an index number instead of hardcoded AZ names:
In variables.tf:
hclvariable "public_subnets" {
  type = map(object({
    cidr_block = string
    az_index   = number  # Index instead of AZ name
    public     = bool
  }))
}
In terraform.tfvars:
hclpublic_subnets = {
  "public-1" = {
    cidr_block = "10.0.1.0/24"
    az_index   = 0  # First AZ in any region
    public     = true
  }
  "public-2" = {
    cidr_block = "10.0.2.0/24"
    az_index   = 1  # Second AZ in any region
    public     = true
  }
}
Why this works:

az_index = 0 will select the first available AZ regardless of region
In us-east-1, index 0 might be us-east-1a
In eu-west-1, index 0 might be eu-west-1a
The code adapts automatically

5. Syntax Errors I Fixed
Error 1: Missing dot in object access
hcl# ❌ Wrong
cidr_block = each.value_cidr_block

# ✅ Correct
cidr_block = each.value.cidr_block
Error 2: Missing .id attribute
hcl# ❌ Wrong
vpc_id = aws_vpc.principal

# ✅ Correct
vpc_id = aws_vpc.principal.id
Error 3: Inconsistent local reference
hcl# I used both locals.project and local.project
# ✅ Correct syntax is: local.project (singular)
6. CIDR Block Planning
I initially had overlapping CIDR blocks:

10.0.0.0/24
10.0.0.1/24 ❌ This overlaps with the first one!

Fixed:

10.0.1.0/24
10.0.2.0/24
10.0.3.0/24

Each subnet gets its own /24 block within the VPC's /16 range.
7. Complete Working Implementation
networking.tf:
hclresource "aws_vpc" "principal" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = local.project
  }
}

resource "aws_subnet" "public" {
  for_each          = var.public_subnets
  cidr_block        = each.value.cidr_block
  vpc_id            = aws_vpc.principal.id
  availability_zone = data.aws_availability_zones.zones.names[each.value.az_index]
  
  tags = {
    Project = local.project
    Name    = "${local.project}-${each.key}"
  }
}
data.tf:
hcldata "aws_availability_zones" "zones" {
  state = "available"
}
terraform.tfvars:
hclpublic_subnets = {
  "public-1" = {
    cidr_block = "10.0.1.0/24"
    az_index   = 0
    public     = true
  }
  "public-2" = {
    cidr_block = "10.0.2.0/24"
    az_index   = 1
    public     = true
  }
  "public-3" = {
    cidr_block = "10.0.3.0/24"
    az_index   = 2
    public     = true
  }
}
Key Takeaways

Data sources make code portable - Using aws_availability_zones instead of hardcoding makes the same code work in any AWS region
Understanding data structures matters - Knowing the difference between objects and lists prevented hours of debugging
tfvars is for values only - Never try to reference resources or use Terraform expressions in .tfvars files
Index-based approach is flexible - Using numeric indices (az_index) instead of AZ names makes infrastructure truly region-agnostic
Testing across regions - Can easily test by changing the region in providers.tf and running terraform plan

Testing the Region-Agnostic Code
To test that this works in different regions, simply change the region in providers.tf:
hclprovider "aws" {
  region = "eu-west-1"  # Or any other region
}
Run terraform plan and observe that Terraform automatically selects the correct availability zones for that region!
Next Steps

Add validation to ensure az_index doesn't exceed available AZs
Create private subnets using the same pattern
Add NAT gateways and routing tables
Deploy EC2 instances across these dynamically created subnets