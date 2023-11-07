resource "shell_script" "deploy_api" {
  lifecycle_commands {
    create = file("${path.module}/create-deployment.sh")
    delete = file("${path.module}/delete-deployment.sh")
  }

  triggers = var.triggers

  environment = {
    REST_API_ID = var.rest_api_id
    DESCRIPTION = var.description
  }
}

terraform {
  required_providers {
    shell = {
      source = "scottwinkler/shell"
    }
  }
}
