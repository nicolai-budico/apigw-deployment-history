output "rest_api_id" {
  value = aws_api_gateway_rest_api.api.id
}

output "rest_api_name" {
  value = aws_api_gateway_rest_api.api.name
}

output "deployment_id" {
  value = module.deployment.deployment_id
}

output "aws_region" {
  value = var.aws_region
}

output "prod_stage_name" {
  value = var.prod_stage_name
}
