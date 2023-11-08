variable "aws_region" {
  type        = string
  description = "Target AWS Region"
  default     = "us-east-1"
}

variable "api_name" {
  type        = string
  description = "API Gateway REST APIs name"
  default     = "the-api"
}

variable "test_stage_name" {
  type        = string
  description = "Test stage name that will be pointing to the latest deployment after `terraform apply`"
  default     = "test"
}

variable "prod_stage_name" {
  type    = string
  default = "live"
}

variable "lambda_name" {
  type        = string
  description = "Name of the lambda function that serves `/example` endpoint"
  default     = "the-lambda"
}

variable "lambda_runtime" {
  type        = string
  description = "Python runtime to use for lambda function"
  validation {
    condition     = contains(["python3.8", "python3.9", "python3.10"], var.lambda_runtime)
    error_message = "Valid values for var: lambda_runtime are (python3.8, python3.9, python3.10)."
  }
  default = "python3.10"
}
