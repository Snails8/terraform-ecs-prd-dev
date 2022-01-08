# ECSに紐付けて使用
output "cluster_name" {
  value = aws_ecs_cluster.main.name
}

# worker を使用
output "cluster_arn" {
  value = aws_ecs_cluster.main.arn
}