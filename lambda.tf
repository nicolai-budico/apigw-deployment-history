data "aws_iam_policy_document" "lambda_sts_policy" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_cloudwatch_log_group" "lambda_log" {
  name              = "/aws/lambda/${var.lambda_name}"
  retention_in_days = 7
}

data "aws_iam_policy_document" "lambda_policy" {
  version = "2012-10-17"
  statement {
    sid    = "WriteLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "${aws_cloudwatch_log_group.lambda_log.arn}:*"
    ]
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.lambda_name}-role"
  path               = "/service-role/"
  assume_role_policy = data.aws_iam_policy_document.lambda_sts_policy.json
  inline_policy {
    name   = "WriteLogs"
    policy = data.aws_iam_policy_document.lambda_policy.json
  }
}

data "archive_file" "lambda" {
  type = "zip"

  source {
    content  = file("${path.module}/lambda_function.py")
    filename = "lambda_function.py"
  }

  output_file_mode = "0666"
  output_path      = "${path.module}/.data/lambda_function.zip"
}

resource "aws_lambda_function" "lambda" {
  function_name                  = var.lambda_name
  role                           = aws_iam_role.lambda.arn
  filename                       = data.archive_file.lambda.output_path
  source_code_hash               = data.archive_file.lambda.output_base64sha256
  handler                        = "lambda_function.lambda_handler"
  memory_size                    = 128
  package_type                   = "Zip"
  reserved_concurrent_executions = -1
  runtime                        = var.lambda_runtime
  timeout                        = 3
  publish                        = true
  layers = [
  ]
  tracing_config {
    mode = "PassThrough"
  }
}

module "lambda_permissions" {
  source        = "./modules/lambda-permissions"
  statement_id  = "allow-apigw-invoke"
  function_name = aws_lambda_function.lambda.function_name
  qualifier     = aws_lambda_function.lambda.version
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/GET/example"
}
