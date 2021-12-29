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

variable "sg" {
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

variable "entry_container_name" {
  type        = string
  description = "Entrypoint container name ex:nginx or worker is expected"
}
variable "entry_container_port" {
  type        = number
  description = "Entrypoint container port number ex:nginx or worker port is expected"
}
variable "service_registries_arn" {
  type        = string
  description = "Service Registry arn used for alignment containers"
}

# cloudwatch eventで使用
variable "cluster_arn" {
  type = string
}

variable "vpc_id" {
  type = string
}