variable "statement_id" {
  type = string
  default = "CallFromAPIGW"
}

variable "principal" {
  type = string
  default = "apigateway.amazonaws.com"
}

variable "source_arn" {
  type = string
}

variable "action" {
  type = string
  default = "lambda:InvokeFunction"
}

variable "function_name" {
  type = string
}

variable "qualifier" {
  type = string
}
