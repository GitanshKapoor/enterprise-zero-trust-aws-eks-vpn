module "eks" {
  source = "./eks"

  vpc_cidr            = var.vpc_cidr
  cluster_name        = "${var.project_name}-cluster"
  cluster_role        = module.iam.cluster_manager_arn
  worker_node_role    = module.iam.worker_node_arn
  public_subnet_ids   = module.vpc.public_subnet_ids
  private_subnet_ids  = module.vpc.private_subnet_ids
  machine_type        = var.machine_type

  depends_on = [module.iam, module.vpc]
  
}

module "iam" {
  source = "./iam"
}

module "vpc" {
  source = "./vpc"

  vpc_name = "${var.project_name}-vpc"
  vpc_cidr = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "vpn" {
  source = "./vpn"

  project_name       = var.project_name
  vpn_cidr_block     = var.vpn_cidr
  vpc_cidr           = var.vpc_cidr
  private_subnet_ids = module.vpc.private_subnet_ids
}