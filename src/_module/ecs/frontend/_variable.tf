variable "app_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

# ECSのsg
variable "sg_list" {
  description = "ECS security group.HTTP/HTTP security group is expected"
  type        = list(string)
}

# ecs  で 使用
variable "private_subnet_ids" {
  type = list(string)
}

# ALB target groupの設定
variable "target_group_arn" {
  type = string
}

# cluster
variable "cluster_name" {
  type = string
}

# タスクに関連付けるIAM
variable "iam_role_task_execution_arn" {
  type = string
}

# ecs task 定義の指定に使用(moduleを使い回すため)
variable "entry_container_port" {
  type = number
}

# task 定義のpath
variable "task_path" {
  type = string
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}

# コンテナ定義を呼び出す(tf 化してあるのでコメントアウトしている)
data "template_file" "container_definitions" {
  template = file("${var.task_path}")  # 指定先を参照

  vars = {
    tag         = "latest"
    name        = var.app_name
    account_id  = local.account_id
    region      = local.region
    port        = var.entry_container_port     #frontendのポート番号を渡したいがうまく行かない
  }
}