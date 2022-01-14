# ==============================================================
# RDS Aurora

# マネージドになり管理しやすくなる
# データの読み書き速度が向上している
# cluster とinstance 作るだけだのでさほど変わらない
# 違い
# https://dev.classmethod.jp/articles/developers-io-2019-in-osaka-aurora-or-rds/
# ==============================================================
resource "aws_db_subnet_group" "main" {
  name        = lower(var.database_name)   # 目的としてはvalidation で弾かれるため、lower で修正している
  description = var.database_name
  subnet_ids  = var.private_subnet_ids
}

# ==============================================================
# RDS cluster の作成
# ==============================================================
resource "aws_rds_cluster" "postgresql" {
  cluster_identifier              = lower(var.app_name)

  engine                          = "aurora-postgresql"
  engine_version                  = "11.7"                 # aurora の一番下のversionがこれ
  engine_mode                     = "provisioned"

  availability_zones              = var.azs
  db_subnet_group_name            = aws_db_subnet_group.main.name
  vpc_security_group_ids          = [var.db_sg_id]
  skip_final_snapshot             = true # 検証 の場合true / 本番はfalse

  database_name                   = var.database_name
  master_username                 = var.master_username
  master_password                 = var.master_password

  # Backup保持期間  注意 https://qiita.com/kt_higa/items/858955c1aa5491f8964e
  backup_retention_period         = 5
  enabled_cloudwatch_logs_exports = ["postgresql"]
  preferred_backup_window         = "07:00-09:00"

  tags = {
    Name = "${var.app_name}-aurora-cluster"
  }
}

# ==============================================================
# instance 作成

# SG で port=5432 を指定している
# ==============================================================
resource "aws_rds_cluster_instance" "postgresql" {
  count              = 2    # スタンバイと本番の２つ(落ちたときの対策)
  identifier         = "${var.app_name}-${count.index}"
  cluster_identifier = aws_rds_cluster.postgresql.cluster_identifier

  instance_class     = "db.t3.medium"
  engine             = "aurora-postgresql"
  engine_version     = "11.7"

  # monitoring
  performance_insights_enabled = false # default false
  monitoring_interval          = 60    # 0, 1, 5, 10, 15, 30, 60 (seconds). default 0 (off)
  monitoring_role_arn          = aws_iam_role.postgresql.arn

  preferred_maintenance_window = "Mon:03:00-Mon:04:00"

  # options
  db_parameter_group_name    = aws_db_parameter_group.postgresql.name
  auto_minor_version_upgrade = false

  # tags
  tags = {
    Name = "${var.app_name}-aurora-instance"
  }
}

# ==============================================================
# DB  パラメーターグループの作成

# RDS の管理に使っている
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_parameter_group
# ==============================================================
resource "aws_db_parameter_group" "postgresql" {
  name   = "${var.app_name}-aurora-postgre-pg"
  family = "aurora-postgresql11"  # ここの値で指定している
}