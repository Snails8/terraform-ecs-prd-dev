# ================================================================
# ecsのendpoint設定 (ecs のsg)
# ================================================================
resource "aws_security_group" "ecs_endpoint" {
  name   = "${var.app_name}-vpc_endpoint_sg"
  vpc_id = var.vpc_id

  # 入り口を定義しないとprivate構成では503になる
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "Name" = "${var.app_name}-ecsEndpoint"
  }
}

# nginx との通信
resource "aws_security_group_rule" "ecs_endpoint" {

  security_group_id = aws_security_group.ecs_endpoint.id

  type = "ingress"

  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]  # 同一VPC内からのアクセスのみ許可 (0.0.0.0/0 だと502 bad wayになる)
}