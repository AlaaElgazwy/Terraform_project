output "rds_endpoint" {
  value = aws_db_instance.app_db.address
}

output "redis_endpoint" {
  value = aws_elasticache_cluster.app_cache.cache_nodes[0].address
}