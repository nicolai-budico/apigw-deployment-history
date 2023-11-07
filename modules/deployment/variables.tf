variable "rest_api_id" {
  type = string
}

variable "description" {
  type = string
  default = ""
}

variable "triggers" {
  type = map(string)
  default = {}
}
