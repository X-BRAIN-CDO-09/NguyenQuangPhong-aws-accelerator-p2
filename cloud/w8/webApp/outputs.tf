output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "ec2_instance_id" {
  description = "Web server instance ID"
  value       = module.ec2.instance_id
}

output "ec2_public_ip" {
  description = "Web server public IP"
  value       = module.ec2.eip_public_ip
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.db_endpoint
}

output "rds_password_secret_arn" {
  description = "Secrets Manager ARN for RDS password"
  value       = module.rds.db_password_secret_arn
}

output "s3_bucket_id" {
  description = "S3 bucket ID"
  value       = module.s3.bucket_id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = module.s3.bucket_arn
}
