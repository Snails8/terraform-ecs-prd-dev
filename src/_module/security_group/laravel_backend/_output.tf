# ALB / ECS / Worker で使用
output "alb_http_sg_id" {
  value = aws_security_group.alb_http.id
}

# ECS / Worker / vpc_endpoint  で使用
output "ecs_sg_id" {
  value = aws_security_group.ecs_endpoint.id
}

# redis / Worker で使用
output "redis_ecs_sg_id" {
  value = aws_security_group.redis_ecs.id
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