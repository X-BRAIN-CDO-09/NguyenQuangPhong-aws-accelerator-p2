output "alb_dns" {
  description = "ALB DNS name - dùng để curl test app"
  value       = aws_lb.this.dns_name
}

output "public_ip" {
  description = "EC2 public IP - dùng để SSH debug"
  value       = aws_instance.k8s.public_ip
}

output "private_key" {
  description = "SSH private key - lưu ra file để SSH: terraform output -raw private_key > challenge.pem && chmod 400 challenge.pem"
  value       = tls_private_key.this.private_key_pem
  sensitive   = true
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.k8s.id
}

output "tg_arn" {
  description = "ALB Target Group ARN - dùng để verify health check: aws elbv2 describe-target-health --target-group-arn $(terraform output -raw tg_arn)"
  value       = aws_lb_target_group.this.arn
}
