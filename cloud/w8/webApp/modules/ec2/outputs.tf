output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.web.id
}

output "instance_public_ip" {
  description = "EC2 public IP"
  value       = aws_instance.web.public_ip
}

output "instance_private_ip" {
  description = "EC2 private IP"
  value       = aws_instance.web.private_ip
}

output "eip_id" {
  description = "Elastic IP ID"
  value       = aws_eip.web.id
}

output "eip_public_ip" {
  description = "Elastic IP public IP"
  value       = aws_eip.web.public_ip
}

output "iam_instance_profile_name" {
  description = "IAM instance profile name"
  value       = aws_iam_instance_profile.ec2.name
}

output "iam_role_name" {
  description = "IAM role name"
  value       = aws_iam_role.ec2.name
}