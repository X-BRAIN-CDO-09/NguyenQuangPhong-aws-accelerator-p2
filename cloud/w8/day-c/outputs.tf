output "instance_id" {
  description = "ID of the EC2 instance"
  value       = module.web_server.instance_id
}

output "instance_public_id" {
  description = "Public IP of the EC2 instance"
  value       = module.web_server.public_ip
}
