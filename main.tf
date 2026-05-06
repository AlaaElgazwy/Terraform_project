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
