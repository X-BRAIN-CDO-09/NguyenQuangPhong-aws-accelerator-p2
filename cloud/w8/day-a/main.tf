provider "aws" {
  region = "us-west-2"

  access_key                  = "anAccesskey"
  secret_key                  = "aSecretKey"
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ec2 = "http://localhost:4566"
  }
}

data "aws_ami" "linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amazn2-ami-hvm-2.0.*-x86_64-ebs"]
  }

  owners = ["137112412989"] # Amazon
}

resource "aws_instance" "app_server" {
  ami           = data.aws_ami.linux.id
  instance_type = var.instance_type

  tags = {
    Name = var.instance_name
  }
}

# data "resourceType" "resourceName"
# resource.resourceType.resourceName == resourceAddress (ex: data.aws_ami.ubuntu)

# FLOWS:
# 1. terraform fmt
# 2. terraform init
# 3. aws configure list
# 4. terraform apply
