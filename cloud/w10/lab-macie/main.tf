terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }
}

provider "aws" {
  region = var.region
}

# ---------------------------------------------------------------------------
# S3 Bucket + sample data
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "demo" {
  bucket        = "macie-demo-bucket-${var.bucket_suffix}"
  force_destroy = true
  tags          = var.tags
}

resource "aws_s3_bucket_versioning" "demo" {
  bucket = aws_s3_bucket.demo.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "employees" {
  bucket  = aws_s3_bucket.demo.id
  key     = "data/employees.csv"
  content = <<-CSV
    name,email,ssn,credit_card
    John Doe,john.doe@example.com,123-45-6789,4111-1111-1111-1111
    Jane Smith,jane.smith@test.org,987-65-4321,5500-0000-0000-0004
    Bob Johnson,bob.j@demo.net,456-78-9012,3782-8224-6310-0005
    Alice Williams,alice.w@sample.com,321-54-9876,6011-1111-1111-1117
    Charlie Brown,charlie.b@example.org,654-32-1987,3530-1113-3330-0000
  CSV
}

resource "aws_s3_object" "customers" {
  bucket  = aws_s3_bucket.demo.id
  key     = "data/customers.csv"
  content = <<-CSV
    id,full_name,email,phone,ssn
    1001,Maria Garcia,maria.garcia@email.com,555-0101,111-22-3333
    1002,James Wilson,james.wilson@mail.net,555-0102,444-55-6666
    1003,Sarah Davis,sarah.davis@test.com,555-0103,777-88-9999
    1004,Michael Brown,michael.b@company.org,555-0104,222-33-4444
    1005,Emma Thompson,emma.t@domain.com,555-0105,888-99-0000
  CSV
}

resource "aws_s3_object" "notes" {
  bucket  = aws_s3_bucket.demo.id
  key     = "internal/notes.txt"
  content = <<-EOF
    Meeting Notes - Q3 Planning
    ============================
    Attendees: John (john.doe@example.com), Sarah (sarah.d@company.com)

    Action Items:
    - Process payroll adjustments for employee SSNs: 123-45-6789, 987-65-4321
    - Update billing system with card ending in 1111
    - Send follow-up to alice.w@sample.com regarding account #6011-1111-1111-1117

    Notes:
    Contact charlie.b@example.org about the new vendor agreement.
    Credit line increase approved for account 3782-8224-6310-0005.
  EOF
}

resource "aws_s3_object" "payroll" {
  bucket  = aws_s3_bucket.demo.id
  key     = "internal/payroll/q2-2025.csv"
  content = <<-CSV
    employee_id,name,ssn,annual_salary
    E001,John Doe,123-45-6789,85000
    E002,Jane Smith,987-65-4321,92000
    E003,Bob Johnson,456-78-9012,78000
    E004,Alice Williams,321-54-9876,110000
    E005,Charlie Brown,654-32-1987,95000
  CSV
}

# ---------------------------------------------------------------------------
# Amazon Macie
# ---------------------------------------------------------------------------
resource "aws_macie2_account" "main" {
  # Macie will be enabled in the current region
  depends_on = [aws_s3_bucket.demo]
}

resource "time_sleep" "macie_propagation" {
  depends_on       = [aws_macie2_account.main]
  create_duration  = "60s"
}

resource "aws_macie2_classification_job" "demo" {
  job_type = "ONE_TIME"
  name     = "macie-demo-sensitive-data-scan"
  s3_job_definition {
    bucket_definitions {
      account_id = data.aws_caller_identity.current.account_id
      buckets    = [aws_s3_bucket.demo.id]
    }
    scoping {
      excludes {
        and {
          simple_scope_term {
            key          = "OBJECT_EXTENSION"
            comparator   = "NE"
            values       = ["txt"]
          }
        }
      }
    }
  }
  sampling_percentage = 100
  tags                = var.tags

  depends_on = [time_sleep.macie_propagation]
}

data "aws_caller_identity" "current" {}

# ---------------------------------------------------------------------------
# SNS Topic for alerts
# ---------------------------------------------------------------------------
resource "aws_sns_topic" "macie_alerts" {
  name         = "macie-alerts-topic"
  display_name = "Macie Findings Alerts"
  tags         = var.tags
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.macie_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    sid    = "AllowEventBridgeToPublish"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.macie_alerts.arn]
  }
}

resource "aws_sns_topic_policy" "macie_alerts" {
  arn    = aws_sns_topic.macie_alerts.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

# ---------------------------------------------------------------------------
# EventBridge Rule for Macie Findings
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_event_rule" "macie_findings" {
  name        = "macie-finding-alert"
  description = "Capture Macie findings and send to SNS"
  event_pattern = jsonencode({
      source      = ["aws.macie"]
    detail-type = ["Macie Finding"]
    detail = {
      severity = {
        description = ["High", "Medium"]
      }
    }
  })
  tags = var.tags
}

resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.macie_findings.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.macie_alerts.arn
}
