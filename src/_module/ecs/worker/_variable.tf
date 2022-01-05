variable "app_name" {
  type = string
}

variable "cluster" {
  description = "ECS Cluster"
  type        = string
}

variable "iam_role_task_exection_arn" {
  description = "ECS Task execution IAM role arn"
  type        = string
}

# public subnetに配置するか、private subnetに配置するかを制御する
variable "placement_subnet" {
  description = "ECS placement subnet.Public subnet or Private subnet is expected."
  type        = list(string)
}

variable "sg_list" {
  description = "ECS security group.HTTP/HTTP security group is expected"
  type        = list(string)
}

# variable "target_group_arn" {
#   type = string
# }

# variable "task_definition_file_path" {
#   type        = string
#   description = "absosule path container definition file ex:../../module/ecs/container_definitions.json"
# }

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}

data "template_file" "container_definitions" {
  template = file(abspath("./worker/worker_container_definitions.json"))
  # templateのjsonファイルに値を渡す
  vars = {
    tag                  = "latest"
    name                 = var.app_name
    entry_container_name = "worker"
    entry_container_port = 6379
    account_id           = local.account_id
    region               = local.region
  }
}

# cloudwatch eventで使用
variable "cluster_arn" {
  type = string
}

variable "vpc_id" {
  type = string
}

# cloudmap しかし規模的に規模的に効果を見込めなかったので修正
#variable "service_registries_arn" {
#  type        = string
#  description = "Service Registry arn used for alignment containers"
#}