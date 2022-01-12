# variable
locals {
  app_name = "housebokan-admin-rea"

  domain = "sub.snails8.site"
  zone   = "sub.snails8.site"
}

# ==========================================================
# ACM 発行
# ==========================================================
module "front_acm" {
  source   = "../_module/acm"
  app_name = local.app_name
  zone     = local.zone
  domain   = local.domain
}

# ==========================================================
# ELB の設定
# ==========================================================
module "front_alb" {
  source            = "../_module/alb"
  app_name          = local.app_name
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  alb_sg            = module.frontend_sg.frontend__alb_sg_id
  target_group_port = 80

  domain = local.domain
  zone   = local.zone
  acm_id = module.front_acm.acm_id
}

# ==========================================================
# IAM 設定 (共通利用するのでコメントアウト
# ==========================================================
module "front_iam" {
  source   = "../_module/iam"
  app_name = local.app_name

  # GithubのOICDで使用  *重複しているのでコメントアウト
#  system      = local.app_name
#  github_repo = "Snails8d/next-spa"
}

# ==========================================================
# フロント用のSG
# ==========================================================
module "frontend_sg" {
  source = "../_module/security_group/frontend"
  app_name             = local.app_name
  vpc_cidr             = var.vpc_cidr
  vpc_id               = module.network.vpc_id
  private_route_table  = module.network.route_table_private
  private_subnets      = module.network.private_subnet_ids
}

# ========================================================
# ECS 作成
# ========================================================
module "front_ecs" {
  source             = "../_module/ecs/frontend"
  app_name           = local.app_name
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids

  cluster_name                = module.ecs_cluster.cluster_name
  target_group_arn            = module.front_alb.aws_lb_target_group    # alb の設定
  iam_role_task_execution_arn = module.iam.iam_role_task_execution_arn  # ECS のtask に関連付けるIAM の設定
  entry_container_port        = 3000  # task定義とECSのALB設定に渡すport

  sg_list = [
    module.frontend_sg.frontend__alb_sg_id,  # front 用の ALBの設定(nginxとの通信はしないのでecsの設定は不要)
  ]
}