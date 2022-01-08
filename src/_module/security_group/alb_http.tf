# ==========================================================
# ALB のsg 設定

#
# ==========================================================
resource "aws_security_group" "alb_http" {
  name        = "${var.app_name}-alb"
  description = "${var.app_name}-alb"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.app_name}-alb"
  }
}

# ==========================================================
# egress
# ==========================================================
resource "aws_security_group_rule" "http_egress" {
  security_group_id = aws_security_group.alb_http.id
  type              = "egress"

  # セキュリティグループ内のリソースからインターネットへのアクセスを許可する
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "https_egress" {
  security_group_id = aws_security_group.alb_http.id
  type              = "egress"
  # ここをcidr_blocks = var.cidr_blocks
  cidr_blocks = ["0.0.0.0/0"]
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
}

# ==========================================================
# ingress
# ==========================================================
# nginxとの通信
resource "aws_security_group_rule" "http_ingress" {
  security_group_id = aws_security_group.alb_http.id

  # セキュリティグループ内のリソースへインターネットからのアクセスを許可する
  type = "ingress"

  from_port = 80
  to_port   = 80
  protocol = "tcp"

  cidr_blocks = ["0.0.0.0/0"]
}

# ALB用セキュリティグループへhttpsも受け付けるようルールを追加する
resource "aws_security_group_rule" "https_ingress" {
  security_group_id = aws_security_group.alb_http.id

  type = "ingress"

  from_port = 443
  to_port   = 443
  protocol  = "tcp"

  cidr_blocks = ["0.0.0.0/0"]
}