provider "aws" {
  region = "us-west-2"
}

module "web_server" {
  source = "./modules/ec2-instance"

  instance_name = "web-server-module"
  instance_type = "t2.micro"
  ami_id        = "ami-..."
}
