# ecs で使用
output "ecs_sg_id" {
  value = aws_security_group.ecs.id
}

# redis で使用
output "redis_ecs_sg_id" {
  value = aws_security_group.redis_ecs.id
}

# ALB / ECSでも使用
output "alb_sg_id" {
  value = aws_security_group.main.id
}

# worker で使用
output "ses_ecs_sg_id" {
  value = aws_security_group.ses_ecs.id
}