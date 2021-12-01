locals {
  name = "${var.app_name}-redis"
}

# ========================================================
# Elasticache (Redis)
# ========================================================
resource "aws_elasticache_cluster" "main" {
  cluster_id         = var.app_name
  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [aws_security_group.main.id]

  engine          = "redis"
  engine_version  = "5.0.6"
  port            = 6379
  parameter_group_name = "default.redis5.0"
  node_type       = "cache.t3.micro"
  num_cache_nodes = 1
}

# Security Group
resource "aws_security_group" "main" {
  name        = local.name
  description = local.name

  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = local.name
  }
}

resource "aws_security_group_rule" "redis" {
  security_group_id = aws_security_group.main.id

  type = "ingress"

  from_port   = 6379
  to_port     = 6379
  protocol    = "tcp"
  cidr_blocks = ["10.1.0.0/16"]
}

resource "aws_elasticache_subnet_group" "main" {
  name        = local.name
  description = local.name
  subnet_ids  = var.private_subnet_ids
}