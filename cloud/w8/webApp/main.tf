provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = "webApp"
      ManagedBy   = "Terraform"
    }
  }
}

module "vpc" {
  source = "./modules/vpc"

  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  azs                  = var.azs
  environment          = var.environment
}

module "security_groups" {
  source = "./modules/security-groups"

  vpc_id      = module.vpc.vpc_id
  environment = var.environment
  # Change this to your public IP (e.g., "203.0.113.0/32")
  allowed_ssh_cidr = var.allowed_ssh_cidr
}

module "ec2" {
  source = "./modules/ec2"

  environment        = var.environment
  instance_type      = var.instance_type
  subnet_id          = module.vpc.public_subnet_ids[0]
  security_group_ids = [module.security_groups.ec2_sg_id]
}

module "rds" {
  source = "./modules/rds"

  identifier          = "webapp-db"
  environment         = var.environment
  instance_class      = var.db_instance_class
  db_name             = "webapp"
  username            = var.db_username
  password            = var.db_password
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  security_group_ids  = [module.security_groups.rds_sg_id]
  multi_az            = false
  deletion_protection = var.rds_deletion_protection

  depends_on = [module.vpc]
}

module "s3" {
  source = "./modules/s3"

  bucket_name   = var.s3_bucket_name
  environment   = var.environment
  force_destroy = true
}
