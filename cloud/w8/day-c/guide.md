# Day C — Step-by-Step (State Management + Modules)

---

## Cấu trúc cuối cùng (sau khi làm xong)

```
day-c/
  main.tf              # Gọi module
  variables.tf         # Root variables
  outputs.tf           # Root outputs
  terraform.tf         # Version requirements
  backend.tf           # S3 + DynamoDB (optional)
  modules/
    ec2-instance/
      main.tf          # Resource logic
      variables.tf     # Module inputs
      outputs.tf       # Module outputs
```

---

## Bước 1: Tạo `terraform.tf`

Tạo file `terraform.tf`, **gõ:**

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

**Giống Day A** — version requirements. Giữ cho tất cả config đều có file này.

---

## Bước 2: Tạo module `modules/ec2-instance/`

Tạo thư mục: `mkdir -p modules/ec2-instance`

### File `modules/ec2-instance/variables.tf`

**Gõ:**

```hcl
variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

variable "instance_name" {
  description = "Value of the EC2 instance's Name tag"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}
```

**Khác Day A:** `ami_id` và `instance_name` **không có default** → bắt buộc phải cung cấp khi gọi module. `instance_type` có default = "t2.micro".
**Why:** Module không nên tự quyết định AMI ID — người gọi module phải biết họ đang deploy cái gì.

### File `modules/ec2-instance/main.tf`

**Gõ:**

```hcl
resource "aws_instance" "this" {
  ami           = var.ami_id
  instance_type = var.instance_type
  tags = {
    Name = var.instance_name
  }
}
```

**Khác Day A:**
- Tên resource là `"this"` (convention: module chỉ có 1 resource chính thì đặt tên `this`).
- Không có provider block, không có data source — module chỉ chứa logic của nó.
- Tất cả giá trị đều từ `var.xxx` — input-only contract.

### File `modules/ec2-instance/outputs.tf`

**Gõ:**

```hcl
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.this.id
}

output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.this.public_ip
}

output "private_dns" {
  description = "Private DNS name of the EC2 instance"
  value       = aws_instance.this.private_dns
}
```

**Purpose:** Module trả về thông tin cho root config. Root sẽ dùng `module.web_server.instance_id` để truy cập.

---

## Bước 3: Tạo root `main.tf`

**Gõ:**

```hcl
provider "aws" {
  region = "us-west-2"
}

module "web_server" {
  source = "./modules/ec2-instance"

  instance_name = "web-server-module"
  instance_type = "t2.micro"
  ami_id        = "ami-0c55b159cbfafe1f0"
}
```

**Cú pháp gọi module:**
```
module "<tên>" {
  source = "<đường dẫn>"
  <variable_name> = <value>
}
```

**Giải thích:**
- `module "web_server"` — gọi module, đặt tên là "web_server" để tham chiếu.
- `source = "./modules/ec2-instance"` — đường dẫn tương đối đến module folder.
- Các arguments còn lại map vào variables của module.
- Không có resource block ở root — root chỉ gọi module. Module chứa resource.

**Why tách module?**
- Tái sử dụng: muốn tạo thêm EC2 khác → thêm `module "web_server_2" { source = "./modules/ec2-instance" ... }` với inputs khác.
- Maintain: sửa logic EC2 1 chỗ trong module, tất cả nơi gọi đều cập nhật.
- Chuẩn hóa: cả team dùng cùng module, đảm bảo best practices.

---

## Bước 4: Tạo root `variables.tf`

**Gõ:**

```hcl
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
```

Root variables giúp đổi giá trị từ bên ngoài (CLI hoặc `.tfvars`).

---

## Bước 5: Tạo root `outputs.tf`

**Gõ:**

```hcl
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = module.web_server.instance_id
}

output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = module.web_server.public_ip
}
```

**Cú pháp tham chiếu output của module:** `module.<tên_module>.<output_name>`

---

## Bước 6: Tạo `backend.tf` (cho remote state)

Khi làm việc nhóm, state cần ở central place. **Gõ:**

```hcl
terraform {
  backend "s3" {
    bucket         = "my-tf-state-bucket"
    key            = "day-c/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "tf-state-locks"
    encrypt        = true
  }
}
```

**Giải thích từng dòng:**

| Dòng | Chức năng |
| :--- | :--- |
| `bucket` | S3 bucket chứa state file. Phải tạo thủ công trước. |
| `key` | Path trong bucket (giống file path). |
| `region` | Region của S3 bucket. |
| `dynamodb_table` | DynamoDB table giữ lock. Phải tạo thủ công trước. |
| `encrypt` | Mã hóa state file at-rest. |

**Luồng locking:**
1. `terraform plan/apply` → DynamoDB `PutItem` (acquire lock)
2. Nếu lock đã có người giữ → error "Error acquiring the state lock"
3. Xong → DynamoDB `DeleteItem` (release lock)

**Để chạy backend này cần:**
```bash
# Tạo S3 bucket
aws s3 mb s3://my-tf-state-bucket

# Tạo DynamoDB table
aws dynamodb create-table \
  --table-name tf-state-locks \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --billing-mode PAY_PER_REQUEST
```

**Nếu chưa có AWS account, comment backend.tf lại để dùng local state** — vẫn chạy được, chỉ không có remote state.

---

## Bước 7: Chạy

```bash
export AWS_ACCESS_KEY_ID=your_key
export AWS_SECRET_ACCESS_KEY=your_secret
export AWS_DEFAULT_REGION=us-west-2

cd cloud/w8/day-c
terraform init        # Init backend + download module
terraform fmt         # Format
terraform validate    # Syntax check
terraform plan        # Preview
terraform apply       # Deploy

# Kiểm tra
terraform state list
terraform state show module.web_server.aws_instance.this

# Dọn dẹp
terraform destroy
```

---

## So sánh Day A vs Day C

| | Day A | Day C |
| :--- | :--- | :--- |
| **State** | Local (`terraform.tfstate`) | Remote (S3 + DynamoDB) |
| **EC2** | Viết trực tiếp trong `main.tf` | Module riêng, gọi từ root |
| **Tái sử dụng** | Không | Có — gọi module nhiều lần |
| **Code structure** | Mọi thứ ở root | Root + modules/ riêng |
| **Maintain** | Sửa nhiều chỗ | Sửa 1 chỗ trong module |

---

## Why tổng quát

| Practice | Why |
| :--- | :--- |
| **S3 + DynamoDB state** | Team không conflict, centralized, CI/CD tích hợp được |
| **Module** | Reusable, DRY, chuẩn hóa, dễ maintain |
| **Input-only contract** | Module là black box, không phụ thuộc root |
| **ADR** | Ghi lại "tại sao", tránh tranh luận lại, người mới hiểu nhanh |
| **Không commit credentials** | AWS key leaked → attacker launch hàng ngàn EC2 → bill khủng |
| **.gitignore (.terraform/, *.tfstate)** | Không commit binary + sensitive data vào Git |
