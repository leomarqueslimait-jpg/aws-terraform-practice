terraform {
  required_version = "~>1.7"
  required_providers {
    aws = {
      version = "~>5.0"
      source  = "hashicorp/aws"
    }
    #archive provider is necessary so we can zip the lambda function
    archive = {
      source  = "hashicorp/archive"
      version = "~>2.0"
    }

  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      ManagedBy = "Terraform"
      Project   = "lambda"
    }
  }
}
    