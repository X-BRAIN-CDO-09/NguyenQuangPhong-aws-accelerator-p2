output "bucket_name" {
  description = "Name of the S3 bucket with sample data"
  value       = aws_s3_bucket.demo.id
}

output "sns_topic_arn" {
  description = "ARN of the SNS alert topic"
  value       = aws_sns_topic.macie_alerts.arn
}

output "classification_job_id" {
  description = "ID of the Macie classification job"
  value       = aws_macie2_classification_job.demo.id
}

output "eventbridge_rule_name" {
  description = "Name of the EventBridge rule"
  value       = aws_cloudwatch_event_rule.macie_findings.name
}

output "next_steps" {
  description = "Post-deploy actions required"
  value = <<-EOT
    1. Confirm the SNS subscription via the email sent to ${var.alert_email}
    2. Wait for the Macie classification job to complete (~5-15 min)
    3. Check Macie console for findings
    4. Trigger a second job to test the EventBridge → SNS alert pipeline
    To tear down: terraform destroy
  EOT
}
