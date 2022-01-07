# provider の設定 ( provider は aws 専用ではなくGCPとかも使える)
provider "aws" {
  region = "ap-northeast-1"
}

# ========================================================
# Network 作成
#
# VPC, subnet(pub, pri), IGW, RouteTable, Route, RouteTableAssociation
# ========================================================
module "network" {
  source = "../_module/network"
  app_name = var.APP_NAME
  azs = var.azs
}

# ========================================================
# SecurityGroup
# ========================================================
module "security_group" {
  source               = "../_module/security_group"
  app_name             = var.APP_NAME
  vpc_cidr             = var.vpc_cidr
  vpc_id               = module.network.vpc_id
  private_route_table  = module.network.route_table_private
  private_subnets      = module.network.private_subnet_ids
}

# ========================================================
# EC2 (vpc_id, subnet_id が必要)
# ========================================================
module "ec2" {
  source = "../_module/ec2"
  app_name = var.APP_NAME
  vpc_id    = module.network.vpc_id
  public_subnet_id = module.network.public_subnet_ids[0]
  ssh_sg_id        = module.security_group.ssh_sg_id
  instance_type    = "t3.nano"
}

# ========================================================
# ECS 作成
#
# ECS(service, cluster elb
# ========================================================
module "ecs" {
  source = "../_module/ecs/app"
  app_name = var.APP_NAME
  vpc_id   = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids

  cluster_name = module.ecs_cluster.cluster_name
  # elb の設定
  target_group_arn               = module.elb.aws_lb_target_group
  # ECS のtask に関連付けるIAM の設定
  iam_role_task_execution_arn = module.iam.iam_role_task_execution_arn
  app_key = var.APP_KEY

  loki_user = var.LOKI_USER
  loki_pass = var.LOKI_PASS

  sg_list = [
    module.security_group.alb_sg_id,  # ALBの設定
    module.security_group.ecs_sg_id,
    module.security_group.redis_ecs_sg_id  # redis
  ]
}
# Frontend

# cluster 作成
module "ecs_cluster" {
  source   = "../_module/ecs/cluster"
  app_name = var.APP_NAME
}

# ==========================================================
# ACM 発行
# ==========================================================
module "acm" {
  source   = "../_module/acm"
  app_name = var.APP_NAME
  zone     = var.ZONE
  domain   = var.DOMAIN
}

# ==========================================================
# ELB の設定
# ==========================================================
module "elb" {
  source            = "../_module/elb"
  app_name          = var.APP_NAME
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  alb_sg            = module.security_group.alb_sg_id

  domain = var.DOMAIN
  zone   = var.ZONE
  acm_id = module.acm.acm_id
}

# ==========================================================
# IAM 設定
# ECS-Agentが使用するIAMロール や タスク(=コンテナ)に付与するIAMロール の定義\
# ==========================================================
module "iam" {
  source = "../_module/iam"
  app_name = var.APP_NAME
}

# ========================================================
# worker 環境
# ========================================================
module "ecs_worker" {
  source = "../_module/ecs/worker"
  # task_definition_file_path      = "../module/ecs/container_definitions.json"
  app_name             = var.APP_NAME
  cluster              = module.ecs_cluster.cluster_name
  placement_subnet     = module.network.private_subnet_ids
  # target_group_arn               = module.alb.aws_lb_target_group
  iam_role_task_exection_arn = module.iam.iam_role_task_execution_arn
  sg_list = [
    module.security_group.http_sg_id,
    module.security_group.ecs_sg_id,
    module.security_group.redis_ecs_sg_id,
    module.security_group.ses_ecs_sg_id
  ]

  # service_registries_arn = module.cloudmap.cloudmap_internal_Arn
  vpc_id                 = module.network.vpc_id
  cluster_arn            = module.ecs_cluster.cluster_arn
}

# 試験的に導入
#module "cloudmap" {
#  source = "../_module/cloudmap"
#  app_name = var.APP_NAME
#  vpc_id   = module.network.vpc_id
#}

# ========================================================
# RDS 作成
# ========================================================
# RDS (PostgreSQL)
module "rds" {
  source = "../_module/rds"

  app_name = var.APP_NAME
  vpc_id   = module.network.vpc_id
  db_sg_id           = module.security_group.db_sg_id
  private_subnet_ids = module.network.private_subnet_ids

  database_name   = var.DB_NAME
  master_username = var.DB_MASTER_NAME
  master_password = var.DB_MASTER_PASS
}

# ========================================================
# Elasticache (Redis)
# ========================================================
module "elasticache" {
  source = "../_module/elasticache"
  app_name = var.APP_NAME
  vpc_id = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  redis_sg_id        = module.security_group.redis_ecs_sg_id
}

# ========================================================
# SES : Simple Email Service
# メール送信に使用
# ========================================================
module "ses" {
  source = "../_module/ses"
  domain = var.DOMAIN
  zone   = var.ZONE
}