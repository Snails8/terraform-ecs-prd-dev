variable "APP_NAME" {
  type = string
}

# AZ の設定(冗長化のため配列でlist化してある)
variable "azs" {
  type = list(string)
  default = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

# ELB で使用 https化に使う
variable "domain" {
  type = string
  default = "snails8.site"
}

# acm で使用 (TLS証明書)
variable "zone" {
  type = string
  default = "snails8.site"
}

variable "APP_KEY" {
  type = string
}

# SSM から取得
data "aws_ssm_parameter" "db_username" {
  name = "/${var.APP_NAME}/TF_VAR_DB_MASTER_NAME"
}

data "aws_ssm_parameter" "db_pass" {
  name = "/${var.APP_NAME}/TF_VAR_DB_MASTER_PASS"
}

data "aws_ssm_parameter" "db_name" {
  name = "/${var.APP_NAME}/TF_VAR_DB_NAME"
}

# RDS で使用。.env に仕込むならこれ
#variable "DB_NAME" {
#  type = string
#}
#
#variable "DB_MASTER_NAME" {
#  type = string
#}
#
#variable "DB_MASTER_PASS" {
#  type = string
#}

# 以下固定化し共有するときに使用
#variable "app_name" {
#  type = string
#  default = "sample"
#}
#variable "domain" {
#  type = string
#  default = "snails8.site"
#}
#
#variable "zone" {
#  type = string
#  default = "snails8.site"
#}