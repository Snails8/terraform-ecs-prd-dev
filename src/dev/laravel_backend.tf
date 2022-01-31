# ========================================================
# EC2 (vpc_id, subnet_id が必要)
# ========================================================
module "ec2" {
  source             = "../_module/ec2"
  app_name           = var.APP_NAME
  vpc_id             = module.network.vpc_id
  public_subnet_id   = module.network.public_subnet_ids[0]

  ssh_sg_id          = module.security_group.ssh_sg_id
  instance_type      = "t3.nano"
  ec2_key_file_path  = "../dev/ec2-key.pub"
}

# ==========================================================
# ELB の設定
# ==========================================================
module "alb" {
  source            = "../_module/alb/https"
  app_name          = var.APP_NAME
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  alb_sg            = module.security_group.alb_http_sg_id
  target_group_port = 80

  domain = var.domain
  zone   = var.zone
  acm_id = module.acm.acm_id
}

# ==========================================================
# cluster (一つのクラスター(箱)の中にserviceを複数 作成する
# ==========================================================
module "ecs_cluster" {
  source   = "../_module/ecs/cluster"
  app_name = var.APP_NAME
}

# ========================================================
# ECS 作成
# ========================================================
module "ecs" {
  source             = "../_module/ecs/laravel_backend/app"
  app_name           = var.APP_NAME
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids

  cluster_name                = module.ecs_cluster.cluster_name
  target_group_arn            = module.alb.aws_lb_target_group           # alb の設定
  iam_role_task_execution_arn = module.iam.iam_role_task_execution_arn   # ECS のtask に関連付けるIAM の設定
  app_key                     = var.APP_KEY
  entry_container_port        = 80

#  loki_user = var.LOKI_USER    使うほどではない
#  loki_pass = var.LOKI_PASS    使うほどではない

  task_path = "../_module/ecs/laravel_backend/app/json/dev_container_definitions.json"

  sg_list = [
    module.security_group.alb_http_sg_id,  # ALBの設定
    module.security_group.ecs_sg_id,
    module.security_group.redis_ecs_sg_id  # redis
  ]
}

# ========================================================
# worker 環境
# ========================================================
module "ecs_worker" {
  source               = "../_module/ecs/laravel_backend/worker"
  app_name             = var.APP_NAME
  vpc_id               = module.network.vpc_id
  placement_subnet     = module.network.private_subnet_ids

  cluster              = module.ecs_cluster.cluster_name
  cluster_arn          = module.ecs_cluster.cluster_arn
  iam_role_task_exection_arn = module.iam.iam_role_task_execution_arn

  task_path = "../_module/ecs/laravel_backend/worker/json/dev_worker_container_definitions.json"

  sg_list = [
    module.security_group.alb_http_sg_id,
    module.security_group.ecs_sg_id,
    module.security_group.redis_ecs_sg_id,
    module.security_group.ses_ecs_sg_id
  ]

  # service_registries_arn = module.cloudmap.cloudmap_internal_Arn
}

# ========================================================
# batch 環境
# ========================================================
module "ecs_batch" {
  source               = "../_module/ecs/laravel_backend/worker"
  app_name             = var.APP_NAME
  vpc_id               = module.network.vpc_id
  placement_subnet     = module.network.private_subnet_ids

  cluster              = module.ecs_cluster.cluster_name
  cluster_arn          = module.ecs_cluster.cluster_arn
  iam_role_task_exection_arn = module.iam.iam_role_task_execution_arn

  task_path = "../_module/ecs/laravel_backend/batch/json/dev_batch_container_definitions.json"

  sg_list = [
    module.security_group.alb_http_sg_id,
    module.security_group.ecs_sg_id,
    module.security_group.redis_ecs_sg_id,
    module.security_group.ses_ecs_sg_id
  ]

  # service_registries_arn = module.cloudmap.cloudmap_internal_Arn
}

# ========================================================
# Cloud Map試験的に導入
# API コール、DNSクエリを介してリソースを検出できる
# ========================================================
# module "cloudmap" {
#  source = "../_module/cloudmap"
#  app_name = var.APP_NAME
#  vpc_id   = module.network.vpc_id
#}