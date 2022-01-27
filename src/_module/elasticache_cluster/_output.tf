#  冗長化
output "redis_hostname" {
  value = aws_elasticache_replication_group.main.configuration_endpoint_address
}