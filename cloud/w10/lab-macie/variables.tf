variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "bucket_suffix" {
  description = "Unique suffix for the S3 bucket name"
  type        = string
}

variable "alert_email" {
  description = "Email address to receive Macie finding alerts via SNS"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project = "macie-lab"
    ManagedBy = "terraform"
  }
}
