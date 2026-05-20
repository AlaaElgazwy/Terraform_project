module "network" {
  source      = "./modules/network"
  vpc_cidr    = var.vpc_cidr
  environment = var.environment
}

module "compute" {
  source            = "./modules/compute"
  environment       = var.environment
  vpc_cidr          = var.vpc_cidr
  
  vpc_id            = module.network.vpc_id
  
  public_subnet_id  = module.network.public_subnet_ids[0] 
  private_subnet_id = module.network.private_subnet_ids[0]
}

# استدعاء موديول قواعد البيانات
module "database" {
  source             = "./modules/database"
  environment        = var.environment
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  app_sg_id          = module.compute.app_sg_id # تأكد أن موديول الـ compute يُخرج هذا الـ ID في ملف outputs.tf الخاص به
}

# استدعاء موديول الإشعارات
module "notifications" {
  source           = "./modules/notifications"
  email_address    = "alaaelgazwy525@gmail.com" 
  state_bucket_arn = "arn:aws:s3:::backend011s3"
}
resource "local_file" "ansible_inventory" {
  filename = "${path.module}/inventory.ini"
  content  = <<EOF
[app_servers]
${module.compute.application_private_ip}

[app_servers:vars]
ansible_user=ubuntu
# الأسطر دي بتخلي Ansible "ينط" للـ App Server عن طريق الـ Bastion
ansible_ssh_common_args='-o ProxyJump=ubuntu@${module.compute.bastion_public_ip} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
rds_endpoint=${module.database.rds_endpoint}
redis_endpoint=${module.database.redis_endpoint}
EOF
}
