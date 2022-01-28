# ============================================================
# acm : AWS Certificate Manager

# ドメインにNSをセットしないといつまで立っても発行されない
# ALBとドメインの紐付けとhttpsの対応
#
# 1. AWS Certificate Manager  => TLS証明書の発行
# 2. Route 53 CNAMEレコード    => TLS証明書発行時にドメインの所有を証明するために作成
# 3. AWS Certificate Manager Validation => TLS証明書発行時にドメインの所有を証明するために作成
# 
# 4. ドメインのドメインの紐付けとhttps 対応はALBの設計なので./alb/main.tfに記載
# ============================================================

# ホストゾーンがないと怒られる
data "aws_route53_zone" "main" {
  name = var.zone
  private_zone = false 
}
# ===================================================================
# ACM TLS証明書の発行
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate
# ===================================================================
resource "aws_acm_certificate" "main" {
  domain_name = var.domain
  subject_alternative_names = [format("*.%s", data.aws_route53_zone.main.name)] # sub ドメインもSSL化
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# ===================================================================
# Route53 CNAMEレコード record 
# TLS証明書発行時にドメインの所有を証明するために作成 
# https://www.terraform.io/docs/providers/aws/r/route53_record.html
# ===================================================================
resource "aws_route53_record" "main" {
  depends_on = [aws_acm_certificate.main]
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}

# ==================================================================
# ACM Validate : AWS Certificate Manager Validation 
# TLS証明書発行時にドメインの所有を証明するために作成 * * ACMでドメインを使用して所有証明をする場合は基本的にCNAMEレコードとワンセットで定義する。
# https://www.terraform.io/docs/providers/aws/r/acm_certificate_validation.html
# ==================================================================
resource "aws_acm_certificate_validation" "main" {
  certificate_arn = aws_acm_certificate.main.arn

  validation_record_fqdns = [for record in aws_route53_record.main : record.fqdn]
}