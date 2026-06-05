variable "instance_name" {
  description = "Value of the EC2 instance's Name tag"
  type        = string
  default     = "web-server-module"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}
