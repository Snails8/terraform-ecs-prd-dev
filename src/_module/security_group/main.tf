# worker で使用
resource "aws_security_group" "http" {
  name        = "${var.app_name}-main"
  description = "${var.app_name}-main"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.app_name}-main"
  }
}

# worker で使用
resource "aws_security_group_rule" "ecs_endpoint" {

  security_group_id = aws_security_group.ecs_endpoint.id

  type = "ingress"

  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

# worker で使用
resource "aws_security_group" "ecs_endpoint" {
  name   = "${var.app_name}-vpc_endpoint_sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  tags = {
    "Name" = "${var.app_name}-ecsEndpoint"
  }
}

# worker で使用
resource "aws_security_group" "ses_ecs" {
  name   = "allow_ses"
  vpc_id = var.vpc_id
  ingress {
    from_port   = 25
    to_port     = 25
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 465
    to_port     = 465
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 465
    to_port     = 465
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 587
    to_port     = 587
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 2465
    to_port     = 2465
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 2587
    to_port     = 2587
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "Name" = "${var.app_name}-ses"
  }
}
