terraform {
  backend "s3" {
  }

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

data "terraform_remote_state" "infrastructure" {
  backend = "s3"
  config = {
    bucket = var.remote_backend_bucket
    key    = var.remote_backend_key
    region = var.remote_backend_region
  }
  workspace = terraform.workspace
}

locals {
  rest_api_id   = data.terraform_remote_state.infrastructure.outputs.rest_api_id
  rest_api_name   = data.terraform_remote_state.infrastructure.outputs.rest_api_name
  deployment_id = data.terraform_remote_state.infrastructure.outputs.deployment_id
  aws_region    = data.terraform_remote_state.infrastructure.outputs.aws_region
  stage_name    = data.terraform_remote_state.infrastructure.outputs.prod_stage_name
}

provider "aws" {
  region = local.aws_region
  default_tags {
    tags = {
      "Application" = "API GW Canary"
      "ManagedBy"   = "terraform"
    }
  }
}
