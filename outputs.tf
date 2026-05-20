output "bastion_public_ip" {
  value = module.compute.bastion_public_ip
}

output "application_private_ip" {
  value = module.compute.application_private_ip
}

output "rds_endpoint" {
  value = module.database.rds_endpoint
}

output "redis_endpoint" {
  value = module.database.redis_endpoint
}