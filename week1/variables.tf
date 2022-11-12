variable "security_group_name" {
  description = "The security group name of webserver"
  type        = string
  default     = "webserver"
}

variable "webserver_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 5000
}
