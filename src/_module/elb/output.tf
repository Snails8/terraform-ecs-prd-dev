# 処理の依存関係上、ココではなくECSに渡してそこでECSコンテナにトラフィックを割り振る
output "aws_lb_target_group" {
  value = aws_lb_target_group.main.arn
}

output "dns_name" {
  value = aws_lb.main.dns_name
}