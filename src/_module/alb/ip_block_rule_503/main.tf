## ip制限かける
resource "aws_lb_listener_rule" "allow_ip" {
  listener_arn = var.listener_arn
  priority = 1
  action {
    type             = "forward"
    target_group_arn = var.target_group_arn
  }

  # allow ip list
  condition {
    source_ip {
      values = ["xx.xx.xx.xx/32"]
    }
  }
}
# ipでの503.
resource "aws_lb_listener_rule" "deny" {
  priority = 2
  listener_arn = var.listener_arn

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/html"
      message_body = file("${path.module}/error.html")
      status_code  = "503"
    }
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}
