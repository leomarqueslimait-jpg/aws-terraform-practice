The goal of this project is to work practice the deployment of different meta-arguments such as count and for_each in creating EC2 instances, multiple subnets, multiple AMIs in the configuration subnets, validation, list and maps.

We will start by making the provider.tf file with the required version and required_providers, and providers declaring aws region

terraform {
  required_version = "~> 1.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
provider "aws" {
  region = "us-east-1"
}

We will create a a locals.tf where we can store our local expressions

A networking.tf will store networking configuration: VPC and subnet

Compute.tf will store ec2 instances configuration
Variables.tf will store the variables expressions