variable "function_name" { type = string }
variable "handler"       { type = string }
variable "runtime"       { type = string }
variable "role_arn"      { type = string }
variable "source_dir"    { type = string }
variable "environment_vars" {
  type    = map(string)
  default = {}
}