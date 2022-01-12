# =====================================================
# terraform init 実行する際に自動でs3に参照しに行く
# したがって、毎回pull する必要もない

# ただこの構成だと同時にapplyを実行させると衝突してしまうので注意
# =====================================================

terraform {
  backend "s3" {
    bucket = "tfstate-snail-prod"
    key    = "dev/terraform.tfstate"
    region = "ap-northeast-1"
  }
}
