# ========================================================
# Network 作成   (VPC, subnet(pub, pri), IGW, RouteTable, Route, RouteTableAssociation)
# ========================================================
module "network" {
  source    = "../_module/network"
  app_name = var.APP_NAME
  azs      = var.azs
}

# ========================================================
# SecurityGroup
# ========================================================
module "security_group" {
  source               = "../_module/security_group/laravel_backend"
  app_name             = var.APP_NAME
  vpc_cidr             = var.vpc_cidr
  vpc_id               = module.network.vpc_id
  private_route_table  = module.network.route_table_private
  private_subnets      = module.network.private_subnet_ids
}


# ==========================================================
# ACM 発行
# ==========================================================
module "acm" {
  source   = "../_module/acm"
  app_name = var.APP_NAME
  zone     = var.zone
  domain   = var.domain
}

# ==========================================================
# IAM 設定
# ECS-Agentが使用するIAMロール や タスク(=コンテナ)に付与するIAMロール の定義\
# ==========================================================
module "iam" {
  source   = "../_module/iam"
  app_name = var.APP_NAME
}

# GithubのOICDで使用
module "github_iam" {
  source = "../_module/iam/github_oidc"
  system      = var.APP_NAME
  github_repo = "Snails8d/laravel-api"
}

# ========================================================
# RDS (PostgreSQL)
# ========================================================
module "rds" {
  source = "../_module/rds"

  app_name           = var.APP_NAME
  vpc_id             = module.network.vpc_id
  db_sg_id           = module.security_group.db_sg_id
  private_subnet_ids = module.network.private_subnet_ids

  database_name   = data.aws_ssm_parameter.db_name.value
  master_username = data.aws_ssm_parameter.db_username.value
  master_password = data.aws_ssm_parameter.db_pass.value
}

# ========================================================
# RDS Aurora (PostgreSQL)   endpoint , 作成時間に注意!!
# ========================================================
#module "rds" {
#  source = "../_module/aurora"
#
#  app_name           = var.APP_NAME
#  vpc_id             = module.network.vpc_id
#  db_sg_id           = module.security_group.db_sg_id
#  private_subnet_ids = module.network.private_subnet_ids
#  azs                = var.azs
#
#  database_name   = data.aws_ssm_parameter.db_name.value
#  master_username = data.aws_ssm_parameter.db_username.value
#  master_password = data.aws_ssm_parameter.db_pass.value
#}

# ========================================================
# Elasticache (Redis)
# ========================================================
module "elasticache" {
  source             = "../_module/elasticache"
  app_name           = var.APP_NAME
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  redis_sg_id        = module.security_group.redis_ecs_sg_id
}

# ========================================================
# SES : Simple Email Service
# メール送信に使用
# ========================================================
module "ses" {
  source = "../_module/ses"
  domain = var.domain
  zone   = var.zone
}