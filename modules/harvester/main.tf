resource "aws_elasticache_subnet_group" "harvester_redis_subnet_group" {
  name       = "harvester-redis-subnet-group"
  subnet_ids = var.subnet_ids
}

resource "aws_elasticache_cluster" "harvester_redis" {
  cluster_id           = "harvester"
  engine               = "redis"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis5.0"
  engine_version       = "5.0.6"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.harvester_redis_subnet_group.name
  security_group_ids   = [aws_security_group.protect_redis.id]
}

resource "aws_cloudwatch_log_group" "this" {
  name = "/ecs/harvester"
  retention_in_days = 14
}

resource "aws_s3_bucket" "harvester_content_bucket" {
  bucket = var.harvester_content_bucket_name
}
