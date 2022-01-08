# worker で使用
resource "aws_security_group" "http" {
  name        = "${var.app_name}-main"
  description = "${var.app_name}-main"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.app_name}-main"
  }
}

