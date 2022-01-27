variable "app_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

locals {
  name = "${var.app_name}-redis"
}

variable "redis_sg_id" {
  type = string
}

variable "number_cache_clusters" {
  type = number
}

variable "azs" {
  type = list(string)
}
