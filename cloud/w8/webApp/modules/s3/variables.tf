variable "bucket_name" {
  description = "S3 bucket name (must be globally unique)"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "versioning_enabled" {
  description = "Enable bucket versioning"
  type        = bool
  default     = true
}

variable "force_destroy" {
  description = "Force destroy bucket even if not empty"
  type        = bool
  default     = false
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "expiration_days" {
  description = "Days after which objects expire"
  type        = number
  default     = 90
}

variable "noncurrent_version_expiration_days" {
  description = "Days after which noncurrent versions expire"
  type        = number
  default     = 30
}

variable "allow_public_access" {
  description = "Allow public access to the bucket"
  type        = bool
  default     = false
}

variable "sse_algorithm" {
  description = "Server-side encryption algorithm"
  type        = string
  default     = "AES256"
}

variable "logging_bucket_name" {
  description = "S3 bucket name for access logs"
  type        = string
  default     = null
}
