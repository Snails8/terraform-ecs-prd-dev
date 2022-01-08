# Worker で使用
output "http_sg_id" {
  value = aws_security_group.http.id
}

# ECS / Worker で使用
output "ecs_sg_id" {
  value = aws_security_group.ecs_endpoint.id
}

# redis / Worker で使用
output "redis_ecs_sg_id" {
  value = aws_security_group.redis_ecs.id
}

# ALB / ECSでも使用
output "alb_sg_id" {
  value = aws_security_group.main.id
}

# RDS で使用
output "db_sg_id" {
  value = aws_security_group.db.id
}

# ec2の設定で使用
output "ssh_sg_id" {
  value = aws_security_group.ssh.id
}

# worker で使用
output "ses_ecs_sg_id" {
  value = aws_security_group.ses_ecs.id
}