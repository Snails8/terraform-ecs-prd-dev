# ========================================================
# Elasticache (Redis) レプリカ
# 冗長化させる場合必要
# ========================================================
# シャードをまとめるグループ
resource "aws_elasticache_cluster" "replica" {
  cluster_id           = "${var.app_name}-elasticache"
  replication_group_id = aws_elasticache_replication_group.main.id
}

# シャード (読み書き(primary node) + リードレプリカ*n )
resource "aws_elasticache_replication_group" "main" {
  replication_group_id          = "${var.app_name}-replication-group"
  replication_group_description = "redis cluster replication group"
  security_group_ids = [var.redis_sg_id]

  availability_zones            = var.azs
  automatic_failover_enabled    = true
  subnet_group_name             = aws_elasticache_subnet_group.main.name # subnet group name を紐付ける

  engine                 = "redis"
  engine_version         = "5.0.6"
  port                   = 6379
  parameter_group_name   = "default.redis5.0"
  node_type              = "cache.t3.micro"
  number_cache_clusters  = var.number_cache_clusters # local 1 / prod 3
  apply_immediately      = false                 # version を上げる際に自動で反映しない設定
  maintenance_window     = "tue:23:00-wed:01:30"
  snapshot_window        = "07:00-09:00"

  lifecycle {
    ignore_changes = [number_cache_clusters]
  }
}

# subnet group をgroup に付けないといけない
resource "aws_elasticache_subnet_group" "main" {
  name        = local.name
  subnet_ids  = var.private_subnet_ids
}
