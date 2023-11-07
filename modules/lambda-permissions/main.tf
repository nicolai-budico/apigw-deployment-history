resource "shell_script" "dtypes_list_permissions" {
  lifecycle_commands {
    create = file("${path.module}/lambda-permissions-create.sh")
    update = file("${path.module}/lambda-permissions-update.sh")
    delete = file("${path.module}/lambda-permissions-delete.sh")
  }

  environment = {
    STATEMENT_ID  = var.statement_id
    PRINCIPAL     = var.principal
    SOURCE_ARN    = var.source_arn
    ACTION        = var.action
    FUNCTION_NAME = var.function_name
    QUALIFIER     = var.qualifier
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
    shell = {
      source = "scottwinkler/shell"
    }
  }
}
