variable "app_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "azs" {
  type = list(string)
}

variable "db_sg_id" {
  type        = string
  description = "RDB security group"
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "database_name" {
  type = string
}

variable "master_username" {
  type = string
}

variable "master_password" {
  type = string
}

locals {
  name = "${var.app_name}-pgsql"
}

## よりセキュアにしたい場合使用 (事前にSSMでパラメータを設定しておくとよい)
#data "aws_ssm_parameter" "db_username" {
#  name = "/${var.app_name}/DB_USERNAME"
#}
#
#data "aws_ssm_parameter" "db_name" {
#  name = "/${var.app_name}/DB_NAME"
#}
#data "aws_ssm_parameter" "db_password" {
#  name = "/${var.app_name}/DB_PASSWORD"
#}
#
#locals {
#  db_username = data.aws_ssm_parameter.db_username.value
#  db_password = data.aws_ssm_parameter.db_password.value
#  db_name     = data.aws_ssm_parameter.db_name.value
#}