# Day A — Step-by-Step (Terraform cơ bản)

---

## Cấu trúc

```
day-a/
  terraform.tf   # Version requirements
  main.tf        # Provider + resources
  variables.tf   # Input variables
  outputs.tf     # Output values
```

---

## Bước 1: Tạo `terraform.tf`

**Gõ:**

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }
  required_version = ">= 1.2"
}
```

**Mục đích:** Khai báo Terraform + AWS provider version.
**Why:** Đảm bảo cả team dùng cùng version, tránh lỗi "works on my machine".

---

## Bước 2: Tạo `main.tf`

**Gõ:**

```hcl
provider "aws" {
  region = "us-west-2"
}

data "aws_ami" "linux" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amazn2-ami-hvm-2.0.*-x86_64-ebs"]
  }
  owners = ["137112412989"]
}

resource "aws_instance" "app_server" {
  ami           = data.aws_ami.linux.id
  instance_type = var.instance_type
  tags = {
    Name = var.instance_name
  }
}
```

**Giải thích từng block:**

| Block | Loại | Chức năng |
| :--- | :--- | :--- |
| `provider "aws"` | Provider | Kết nối AWS, chọn region. Credentials lấy từ env vars. |
| `data "aws_ami" "linux"` | Data source | Query AMI mới nhất của Amazon Linux 2 — **read-only**, không tạo resource. |
| `resource "aws_instance" "app_server"` | Resource | Tạo EC2 instance thật trên AWS. |

**Why data source thay vì hardcode AMI ID?** AMI ID khác nhau theo region và thay đổi theo thời gian. Data source query động, không sợ outdated.

---

## Bước 3: Tạo `variables.tf`

**Gõ:**

```hcl
variable "instance_name" {
  description = "Value of the EC2 instance's Name tag"
  type        = string
  default     = "learn-terraform"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}
```

**Mục đích:** Parameterize — tách dữ liệu khỏi logic.
**Why:** Cùng code, đổi variables → deploy môi trường khác (dev/staging/prod). DRY — sửa 1 chỗ thay vì nhiều chỗ.
**Cách dùng:** `terraform apply -var="instance_type=t2.large"` hoặc file `terraform.tfvars`.

---

## Bước 4: Tạo `outputs.tf`

**Gõ:**

```hcl
output "instance_hostname" {
  description = "Private DNS name of the EC2 instance"
  value       = aws_instance.app_server.private_dns
}
```

**Mục đích:** Xuất thông tin sau deploy.
**Why:** Cần biết DNS/IP của instance vừa tạo. Output in ra terminal, có thể feed vào hệ thống khác.

---

## Bước 5: Chạy

```bash
export AWS_ACCESS_KEY_ID=your_key
export AWS_SECRET_ACCESS_KEY=your_secret
export AWS_DEFAULT_REGION=us-west-2

cd cloud/w8/day-a
terraform init      # Download provider
terraform fmt       # Format code
terraform validate  # Kiểm tra syntax
terraform plan      # Xem preview
terraform apply     # Deploy
terraform state list # Xem resources trong state
terraform destroy   # Xóa
```

---

## Tổng quan luồng

```
Code (main.tf)  ───►  Terraform đọc, so sánh với state
                            │
                    Gọi AWS API tạo resource
                            │
                    Ghi state (terraform.tfstate)
                            │
                    Output ra terminal
```

---

## Why tổng quát — Tại sao công ty dùng Terraform?

| Vấn đề | Giải pháp | Lợi ích |
| :--- | :--- | :--- |
| Click UI dễ sai | Code hóa hạ tầng | Review được, Git history, tái lập chính xác |
| "Server nào đang chạy?" | State file | Nguồn sự thật duy nhất |
| Dev ≠ Staging ≠ Prod | Variables | Cùng code, khác variables |
| Nhân viên nghỉ, ai biết? | Code trong Git | Git history = documentation |
| Deploy lỗi | `terraform destroy` + code cũ | Git revert + apply lại |
