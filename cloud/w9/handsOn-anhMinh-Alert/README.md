# CPU Alarm Email Alert Hands-On

Console-based hands-on for creating an EC2 CPU CloudWatch alarm that sends email notifications through SNS.

Scenario: send an email alert when EC2 CPU utilization is greater than 80% for 5 consecutive minutes.

## Lab

Follow the step-by-step AWS Console walkthrough in [HANDS_ON.md](./HANDS_ON.md).

## Flow

- Create EC2 instance
- Create IAM role with `CloudWatchAgentServerPolicy`
- Attach IAM role to EC2
- Install and start CloudWatch Agent
- Create SNS topic
- Create email subscription
- Confirm subscription by email
- Create CloudWatch alarm
- Configure CPU greater than 80% for 5 minutes
- Attach SNS notification action
- Optionally generate CPU load to test the email alert
