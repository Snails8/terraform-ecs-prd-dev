# ===========================================================================
# ELB の設定 AWS Elastic Load Balancing
#
# 1. ALBの作成
# 1-1. httpとhttpsの通信を受け取れるように
# 2. 通信を行うためにALBのリスナー設定( http => httpsに流す )
# 3. ECSのnginxに流してやる(処理の依存関係上ココでは行わないのでoutput)
# ACM ECS と依存関係
# ===========================================================================

# ========================================================================
# ALB 作成 。public に配置
# ========================================================================
resource "aws_lb" "main" {
  load_balancer_type = "application"
  internal           = false
  idle_timeout       = 60
  name               = var.app_name

  security_groups    = [var.alb_sg]
  subnets            = var.public_subnet_ids
}

# ============================================================
# 接続リクエストのLBの設定(リスナーの追加) (HTTP)
#
# これがないとALBにアクセスできない。設定するとDNSにアクセスした際にALBがhttpを受け付けるように
# ============================================================
resource "aws_lb_listener" "http" {
  # HTTPでのアクセスを受け付ける
  port = 80
  protocol = "HTTP"

  # ALBのarnを指定( arn: Amazon Resource Names の略で、その名の通りリソースを特定するための一意な名前(id))
  load_balancer_arn = aws_lb.main.arn

  # httpで来たリクエストをhttpsへリダイレクトさせる
  default_action {
    type = "redirect"

    redirect {
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# https
resource "aws_lb_listener" "https" {
  port     = 443
  protocol = "HTTPS"

  # TSL証明書等を受け取る(処理はacm)
  certificate_arn   = var.acm_id
  load_balancer_arn = aws_lb.main.arn
  # "ok" という固定レスポンスを設定する
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      status_code  = "200"
      message_body = "ok"
    }
  }
}

# ==========================================================
# ECS ALB  target group の設定
# ==========================================================
# リスナー: ロードバランサがリクエスト受けた際、どのターゲットグループへリクエストを受け渡すのかの設定
resource "aws_lb_listener_rule" "main" {
  # リスナー(アクセス可能にするALBの設定)の指定
  listener_arn = aws_lb_listener.https.arn

  # 受け取ったトラフィックをターゲットグループへ受け渡す
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  # ターゲットグループへ受け渡すトラフィックの条件
  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

# ターゲットグループ: ヘルスチェック(死活監視)を行う
resource "aws_lb_target_group" "main" {
  name = var.app_name
  vpc_id = var.vpc_id

  # ALBからECSタスクのコンテナへトラフィックを振り分ける設定(ECS(nginx)へ流す)
  target_type          = "ip"
  port                 = var.target_group_port
  deregistration_delay = 300
  protocol             = "HTTP"

  # コンテナへの死活監視設定
  health_check {
    path                = "/"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = 200
    port                = "traffic-port" # routing と同じおRTに自動で変更される(= var.target_group_port)
    protocol            = "HTTP"
  }
}

# =============================================================
# https対応: ドメインと紐付け
# =============================================================
# Route53 A record  ALBとドメインの紐付け用レコード
resource "aws_route53_record" "main" {
  type = "A"

  name    = var.domain
  zone_id = data.aws_route53_zone.main.id

  # = は付けない
  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}