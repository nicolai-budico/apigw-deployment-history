terraform {
  backend "s3" {
  }

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    archive = {
      source = "hashicorp/archive"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      "Application" = "API GW Canary"
      "ManagedBy"   = "terraform"
    }
  }
}
