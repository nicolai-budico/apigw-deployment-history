resource "aws_api_gateway_rest_api" "api" {
  name = var.api_name
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  body = jsonencode({
    openapi = "3.0.1"
    info = {
      title   = "The APIs"
      version = "1.0"
    }
    paths = {
      "/example" = {
        get = {
          x-amazon-apigateway-integration = {
            type                = "aws_proxy"
            httpMethod          = "POST"
            uri                 = aws_lambda_function.lambda.qualified_invoke_arn
            passthroughBehavior = "when_no_match"
            timeoutInMillis     = 29000
          }
          responses = {
            200 = {
              description = "OK"
            }
          }
        }
      }
    }
  })
}

resource "aws_api_gateway_rest_api_policy" "api_policy" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : "execute-api:Invoke",
        "Resource" : "${aws_api_gateway_rest_api.api.execution_arn}/*/*/*"
      },
    ]
  })
}

resource "aws_cloudwatch_log_group" "test_stage" {
  name              = "${var.api_name}/access_log/${var.test_stage_name}"
  retention_in_days = 7
}

module "deployment" {
  source = "./modules/deployment"
  depends_on = [
    aws_api_gateway_rest_api.api
  ]
  triggers = {
    api_changed = sha512(aws_api_gateway_rest_api.api.body)
  }

  rest_api_id = aws_api_gateway_rest_api.api.id
  description = "Deployment ${timestamp()}"
}

resource "aws_api_gateway_stage" "test_stage" {
  depends_on = [
    module.deployment
  ]

  deployment_id = module.deployment.deployment_id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = var.test_stage_name

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.test_stage.arn
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

resource "aws_api_gateway_method_settings" "test_stage" {
  depends_on = [
    aws_api_gateway_stage.test_stage
  ]
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.test_stage.stage_name
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
