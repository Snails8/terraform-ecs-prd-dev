# worker で使用
output "http_sg_id" {
  value = aws_security_group.http.id
}

# ecs で使用
output "ecs_sg_id" {
  value = aws_security_group.ecs.id
}

# worker で使用
output "redis_ecs_sg_id" {
  value = aws_security_group.redis_ecs.id
}

# worker で使用
output "ses_ecs_sg_id" {
  value = aws_security_group.ses_ecs.id
}