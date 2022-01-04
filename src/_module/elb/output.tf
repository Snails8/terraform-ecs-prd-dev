# 処理の依存関係上、ココではなくECSに渡してそこでECSコンテナにトラフィックを割り振る
output "https_listener_arn" {
  value = aws_lb_listener.https.arn
}

output "dns_name" {
  value = aws_lb.main.dns_name
}