resource "aws_cloudwatch_log_group" "live_stage" {
  name              = "${local.rest_api_name}/access_log/${local.stage_name}"
  retention_in_days = 7
}

resource "aws_api_gateway_stage" "live_stage" {
  depends_on = [
    data.terraform_remote_state.infrastructure
  ]

  deployment_id = local.deployment_id
  rest_api_id   = local.rest_api_id
  stage_name    = local.stage_name

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.live_stage.arn
    format = jsonencode({
      "requestId" : "$context.requestId",
      "extendedRequestId" : "$context.extendedRequestId",
      "ip" : "$context.identity.sourceIp",
      "caller" : "$context.identity.caller",
      "user" : "$context.identity.user",
      "requestTime" : "$context.requestTime"
      "httpMethod" : "$context.httpMethod",
      "resourcePath" : "$context.resourcePath",
      "status" : "$context.status",
      "protocol" : "$context.protocol",
      "responseLength" : "$context.responseLength"
      }
    )
  }
  cache_cluster_enabled = false
  xray_tracing_enabled  = false
}

resource "aws_api_gateway_method_settings" "live_stage" {
  depends_on = [
    aws_api_gateway_stage.live_stage
  ]
  rest_api_id = local.rest_api_id
  stage_name  = aws_api_gateway_stage.live_stage.stage_name
  method_path = "*/*"
  settings {
    caching_enabled        = false
    logging_level          = "OFF"
    data_trace_enabled     = false
    metrics_enabled        = false
    throttling_burst_limit = 100
    throttling_rate_limit  = 100
  }
}



