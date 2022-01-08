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

# ===============================================================
# VPC endpoint を作成することで 各種リソースに対応できるようにしてある
# ===============================================================
resource "aws_vpc_endpoint" "s3" {

  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.ap-northeast-1.s3"
  vpc_endpoint_type = "Gateway"
  tags = {
    "Name" = "${var.app_name}-s3-endpoint"
  }
}

resource "aws_vpc_endpoint_route_table_association" "private_s3" {
  count           = length(var.private_subnets)
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  route_table_id  = var.private_route_table[count.index].route_table_id
}



# ================================================================
# Interface型なので各種セキュリティグループと紐づく
# ================================================================
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.ap-northeast-1.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnets
  security_group_ids  = [aws_security_group.ecs.id]
  private_dns_enabled = true
  tags = {
    "Name" = "${var.app_name}-private-ECR_DKR"
  }
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.ap-northeast-1.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnets
  security_group_ids  = [aws_security_group.ecs.id]
  private_dns_enabled = true
  tags = {
    "Name" = "${var.app_name}-private-ECR_API"
  }
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.ap-northeast-1.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnets
  security_group_ids  = [aws_security_group.ecs.id]
  private_dns_enabled = true
  tags = {
    "Name" = "${var.app_name}-private-logs"
  }
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.ap-northeast-1.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnets
  security_group_ids  = [aws_security_group.ecs.id]
  private_dns_enabled = true
  tags = {
    "Name" = "${var.app_name}-private-ssm"
  }
}
resource "aws_vpc_endpoint" "ses" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.ap-northeast-1.qldb.session"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnets
  security_group_ids  = [aws_security_group.ecs.id]
  private_dns_enabled = true
  tags = {
    "Name" = "${var.app_name}-private-ses"
  }
}