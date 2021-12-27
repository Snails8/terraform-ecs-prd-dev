# DB_HOST (正確にはDB_HOST + 5432)
output "db_endpoint" {
  value = module.rds.endpoint
}

# SUBNETSに該当
output "db_subnets" {
  value = module.network.private_subnet_ids
}

# REDIS_HOST
output "redis_hostname" {
  value = module.elasticache.redis_hostname
}

# SECURITY_GROUPに該当
output "db_security_groups" {
  value = module.rds.db_security_group
}

output "aws_vpc" {
  value = module.network.vpc_id
}

# ecs の動作検証に使用
output "alb_dns_name" {
  value = module.elb.dns_name
}

# output "db_step_ip" {
#   value = module.compute.db_step_eip
# }

# github action に乗せる値
output "ecs_exec_role" {
  value = module.iam.iam_role_task_execution_arn
}