output "bucket_name" {
  description = "S3 Bucket for state locking"
  value       = var.bucket_name
}

output "table_name" {
  description = "DynamoDB Table for state locking"
  value       = var.table_name
}
