# Hands-On: CPU Alarm to Email Alert via SNS

## Scenario

Send an email alert when EC2 CPU utilization is greater than 80% for 5 consecutive minutes.

## What You Will Build

```text
EC2 instance
  -> CPUUtilization metric
  -> CloudWatch Alarm
  -> SNS Topic
  -> Email Subscription

CloudWatch Agent
  -> Extra host metrics such as memory and disk
```

## Prerequisites

- Access to the AWS Console
- An email inbox you can access
- Permission to use EC2, IAM, SNS, and CloudWatch

## Step 1: Create an EC2 Instance

1. Open the AWS Console.
2. Search for `EC2`.
3. Open `EC2`.
4. Choose `Instances`.
5. Choose `Launch instances`.
6. For `Name`, enter `cpu-alarm-demo`.
7. Under `Application and OS Images`, select `Amazon Linux`.
8. Choose the latest `Amazon Linux 2023 AMI`.
9. Under `Instance type`, select `t2.micro` or `t3.micro`.
10. Under `Key pair`, choose an existing key pair, or choose `Proceed without a key pair` if you only need the alarm demo.
11. Under `Network settings`, keep the default VPC and subnet.
12. For `Firewall`, choose `Create security group`.
13. If you want to connect with EC2 Instance Connect, allow `SSH` from `My IP`.
14. Keep the default storage settings.
15. Choose `Launch instance`.
16. Open the new instance details page.
17. Copy the `Instance ID`; you will need it when selecting the CloudWatch metric.

Checkpoint: the EC2 instance named `cpu-alarm-demo` should be in the `Running` state.

## Step 2: Attach an IAM Role for CloudWatch Agent

CloudWatch Agent needs permission to send metrics and logs to CloudWatch.

### Create IAM Role

1. Search for `IAM` in the AWS Console.
2. Open `IAM`.
3. In the left menu, choose `Roles`.
4. Choose `Create role`.
5. For `Trusted entity type`, choose `AWS service`.
6. For `Use case`, choose `EC2`.
7. Choose `Next`.
8. Search for `CloudWatchAgentServerPolicy`.
9. Select `CloudWatchAgentServerPolicy`.
10. Choose `Next`.
11. For `Role name`, enter `EC2CloudWatchAgentRole`.
12. Choose `Create role`.

### Attach IAM Role to EC2

1. Open `EC2`.
2. Go to `Instances`.
3. Select `cpu-alarm-demo`.
4. Choose `Actions`.
5. Choose `Security`.
6. Choose `Modify IAM role`.
7. Select `EC2CloudWatchAgentRole`.
8. Choose `Update IAM role`.

Checkpoint: the EC2 instance should now have the IAM role `EC2CloudWatchAgentRole` attached.

## Step 3: Install the CloudWatch Agent on EC2

The basic EC2 `CPUUtilization` metric works without the CloudWatch Agent. The agent is still useful because it enables additional metrics such as memory, disk, swap, and process-level monitoring.

### Connect to the Instance

1. Open `EC2`.
2. Go to `Instances`.
3. Select `cpu-alarm-demo`.
4. Choose `Connect`.
5. Choose the `EC2 Instance Connect` tab.
6. Choose `Connect`.

If the connection fails, see [Troubleshooting EC2 Instance Connect](#troubleshooting-ec2-instance-connect).

### Install the Agent Package

For Amazon Linux:

```bash
sudo yum install amazon-cloudwatch-agent -y
```

For Ubuntu:

```bash
sudo apt-get update
sudo apt-get install amazon-cloudwatch-agent -y
```

### Run the Configuration Wizard

```bash
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard
```

Use simple lab-friendly choices:

- Run on EC2: `yes`
- User: `root`
- StatsD daemon: `no`
- CollectD: `no`
- Monitor host metrics: `yes`
- CPU per core: `yes`
- Add EC2 dimensions: `yes`
- Aggregation dimensions: `InstanceId`
- Metrics collection interval: `60 seconds`
- Config location: default
- Store config in SSM Parameter Store: `no`

### Start the Agent

```bash
sudo systemctl enable amazon-cloudwatch-agent
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json
```

### Verify the Agent Status

```bash
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a status
```

Checkpoint: the status output should show the CloudWatch Agent as `running`.

If the status shows `stopped` and `configstatus: notconfigured`, the agent has not loaded a config yet. Re-run the configuration wizard, then run the `fetch-config` command above.

## Step 4: Create SNS Topic and Email Subscription

### Create SNS Topic

1. Open the AWS Console.
2. Search for `SNS`.
3. Open `Simple Notification Service`.
4. In the left menu, choose `Topics`.
5. Choose `Create topic`.
6. For `Type`, select `Standard`.
7. For `Name`, enter `cpu-alerts`.
8. Choose `Create topic`.

Checkpoint: you should now see an SNS topic named `cpu-alerts`.

### Create Email Subscription

1. Open the `cpu-alerts` topic.
2. Choose `Create subscription`.
3. For `Protocol`, select `Email`.
4. For `Endpoint`, enter your email address.
5. Choose `Create subscription`.
6. Open your email inbox.
7. Find the AWS confirmation email.
8. Click `Confirm subscription`.

Checkpoint: in SNS, the subscription status should change from `Pending confirmation` to `Confirmed`.

## Step 5: Create CloudWatch Alarm

1. Search for `CloudWatch` in the AWS Console.
2. Open `CloudWatch`.
3. In the left menu, choose `Alarms`.
4. Choose `All alarms`.
5. Choose `Create alarm`.
6. Choose `Select metric`.
7. Choose `EC2`.
8. Choose `Per-Instance Metrics`.
9. Search for your EC2 instance ID.
10. Select the metric named `CPUUtilization` for your instance.
11. Choose `Select metric`.

Checkpoint: the alarm should now be based on `AWS/EC2 CPUUtilization` for one EC2 instance.

## Step 6: Configure Alarm Conditions

On the metric and conditions screen:

1. For `Statistic`, select `Average`.
2. For `Period`, select `5 minutes`.
3. Under `Conditions`, choose `Static`.
4. Choose `Greater`.
5. Enter threshold value `80`.
6. Open `Additional configuration` if it is collapsed.
7. For `Datapoints to alarm`, set `1 out of 1`.
8. For `Missing data treatment`, choose `Treat missing data as not breaching`.
9. Choose `Next`.

Checkpoint: the alarm condition should read approximately:

```text
CPUUtilization > 80 for 1 datapoint within 5 minutes
```

## Step 7: Set SNS Notification Action

On the notification screen:

1. For `Alarm state trigger`, choose `In alarm`.
2. For `Send a notification to the following SNS topic`, choose `Select an existing SNS topic`.
3. Select `cpu-alerts`.
4. Optional: choose `Add notification`.
5. Optional: for the second notification, select `OK` as the state trigger.
6. Optional: select the same `cpu-alerts` topic so you receive a recovery email.
7. Choose `Next`.

Checkpoint: the alarm should send email through SNS when it enters the `In alarm` state.

## Step 8: Name and Create the Alarm

1. For `Alarm name`, enter `high-cpu-email-alert`.
2. For `Alarm description`, enter `Email alert when EC2 CPU is greater than 80 percent for 5 minutes`.
3. Choose `Next`.
4. Review the configuration.
5. Choose `Create alarm`.

Checkpoint: CloudWatch should show a new alarm named `high-cpu-email-alert`.

## Optional Step 9: Trigger the Alarm for Testing

If you want to test the email alert, generate CPU load on the EC2 instance.

### Connect From the Console

1. Open `EC2`.
2. Go to `Instances`.
3. Select `cpu-alarm-demo`.
4. Choose `Connect`.
5. Choose the `EC2 Instance Connect` tab.
6. Choose `Connect`.

### Generate CPU Load

In the browser terminal, run:

```bash
sudo dnf install -y stress-ng
stress-ng --cpu 1 --timeout 7m
```

Wait at least 5 minutes. The CloudWatch alarm should move to `In alarm`, then SNS should send an email notification.

If `stress-ng` is unavailable, use this fallback:

```bash
timeout 7m yes > /dev/null
```

Stop the load test by waiting for the timeout to finish, or press `Ctrl+C`.

## Final Verification

Confirm these items:

- SNS topic `cpu-alerts` exists.
- Email subscription is confirmed.
- EC2 instance `cpu-alarm-demo` exists.
- EC2 instance has IAM role `EC2CloudWatchAgentRole` attached.
- CloudWatch Agent is installed and running.
- CloudWatch alarm exists.
- Alarm metric is `CPUUtilization`.
- Alarm threshold is greater than `80`.
- Alarm period is `5 minutes`.
- Alarm sends notifications to the SNS topic.

## Troubleshooting EC2 Instance Connect

If you see `Failed to connect to your instance` or `Error establishing SSH connection to your instance`, check these items.

### Check Instance State

1. Open `EC2`.
2. Go to `Instances`.
3. Select `cpu-alarm-demo`.
4. Confirm `Instance state` is `Running`.
5. Confirm `Status check` is `2/2 checks passed`.

If status checks are still initializing, wait 1 to 2 minutes and retry.

### Check Public IPv4 Address

1. Select the instance.
2. Open the `Details` tab.
3. Confirm `Public IPv4 address` has a value.

If there is no public IPv4 address, EC2 Instance Connect from the browser will not work unless you use a private network path. For this lab, launch the instance in a public subnet with `Auto-assign public IP` enabled.

### Check Security Group SSH Rule

1. Select the instance.
2. Open the `Security` tab.
3. Select the attached security group.
4. Open `Inbound rules`.
5. Confirm there is an inbound rule for `SSH`, port `22`.
6. Source should be your IP address, for example `x.x.x.x/32`.

If missing, choose `Edit inbound rules`, add `SSH`, source `My IP`, then save.

### Check Network ACL and Route Table

For a simple lab using the default VPC, this is usually already correct. If you used a custom VPC, confirm:

- The subnet route table has `0.0.0.0/0` pointing to an Internet Gateway.
- The subnet network ACL allows inbound and outbound SSH traffic.
- The subnet network ACL allows ephemeral response ports.

### Retry Connect

After fixing the above:

1. Go back to `EC2`.
2. Select `cpu-alarm-demo`.
3. Choose `Connect`.
4. Choose `EC2 Instance Connect`.
5. Choose `Connect` again.

## Cleanup

To avoid leaving unused resources:

1. Open CloudWatch.
2. Go to `Alarms`.
3. Select `high-cpu-email-alert`.
4. Choose `Actions`.
5. Choose `Delete`.
6. Open SNS.
7. Delete the email subscription.
8. Delete the `cpu-alerts` topic.
9. Open EC2.
10. Select `cpu-alarm-demo`.
11. Choose `Instance state`.
12. Choose `Terminate instance`.
13. Open IAM.
14. Go to `Roles`.
15. Delete `EC2CloudWatchAgentRole` if it is no longer needed.
