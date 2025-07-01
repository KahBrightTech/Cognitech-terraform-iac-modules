terraform {
  required_version = ">= 1.5.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.37.0"
    }
  }
}

# Default provider configuration
provider "aws" {
  region = "us-east-1" # Adjust this to your desired region
}
