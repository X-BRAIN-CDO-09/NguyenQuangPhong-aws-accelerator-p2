# Detect Sensitive Data in S3 with Amazon Macie

Detect mock sensitive data (SSN, credit cards, email) in S3 using Amazon Macie, with EventBridge → SNS email alerts.

## Prerequisites

- AWS CLI configured with credentials
- Terraform ~> 5.0

## Setup

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — set bucket_suffix and alert_email
terraform init
terraform apply
```

After apply, **confirm the SNS subscription** from the email sent to your inbox.

## Resources Created

| Resource | Description |
|---|---|
| S3 Bucket | Stores sample CSV/txt files with mock sensitive data |
| Amazon Macie | Enabled for the account; one-time classification job scans bucket |
| SNS Topic | Publishes alert emails on Macie findings |
| EventBridge Rule | Matches Macie findings (High/Medium severity) → SNS |

## Triggering Detection

Upload a new file and re-run a classification job:

```bash
BUCKET=$(terraform output -raw bucket_name)
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
aws s3 cp sample-data/employees.csv "s3://$BUCKET/trigger-test/"
aws macie2 create-classification-job --job-type ONE_TIME \
  --name "macie-e2e" \
  --s3-job-definition "{\"bucketDefinitions\":[{\"accountId\":\"$ACCOUNT\",\"buckets\":[\"$BUCKET\"]}]}"
```

Once the job completes, check:
1. **Macie → Findings** in the AWS console
2. **Your email** for the SNS alert

## Tear Down

```bash
terraform destroy
```

This removes all resources: S3 bucket (emptied automatically via `force_destroy`), Macie classification job, EventBridge rule, SNS topic, and subscription.

**Note:** Terraform cannot disable Macie for the account — the service remains enabled but incurs no cost without active jobs. To fully disable Macie, do it manually in the Macie console under **Settings → Deactivate Macie**.
