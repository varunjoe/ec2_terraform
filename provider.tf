terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  required_version = ">= 1.2.0"
  backend "s3" {
    bucket         = "919466768284-terraform-states"
    key            = "ec2-project/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock" # Must be pre-created
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}


