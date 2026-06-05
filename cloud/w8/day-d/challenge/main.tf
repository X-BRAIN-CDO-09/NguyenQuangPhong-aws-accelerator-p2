data "aws_ssm_parameter" "ubuntu_ami" {
  name = "/aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}

# TLS - SSH KEY

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "this" {
  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.this.public_key_openssh

  tags = { Name = "${var.project_name}-key" }
}

# CLOUDINIT - BOOTSTRAP.SH SCRIPT

data "cloudinit_config" "bootstrap" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/bootstrap.sh", {
      node_port        = var.node_port
      deployment_yaml  = file("${path.module}/app/deployment.yaml")
      service_yaml     = templatefile("${path.module}/app/service.yaml", {
        node_port = var.node_port
      })
    })
  }
}

# NETWORK - CUSTOM VPC

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "${var.project_name}-vpc" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = "${var.region}a"

  tags = { Name = "${var.project_name}-subnet-a" }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.0.2.0/24" # khác dải với subnet a
  map_public_ip_on_launch = true
  availability_zone       = "${var.region}b" # AZ khác

  tags = { Name = "${var.project_name}-subnet-b" }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = { Name = "${var.project_name}-igw" }
}

resource "aws_route_table" "this" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = { Name = "${var.project_name}-rt" }
}

resource "aws_route_table_association" "this" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.this.id
}

resource "aws_route_table_association" "this_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.this.id
}

# SECURITY GROUP

resource "aws_security_group" "this" {
  name        = "${var.project_name}-sg"
  description = "Allow SSH from my IP, NodePort from ALB"
  vpc_id      = aws_vpc.this.id

  tags = { Name = "${var.project_name}-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = "${chomp(data.http.my_ip.response_body)}/32"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  description       = "SSH from my IP"
}

resource "aws_vpc_security_group_ingress_rule" "nodeport" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = var.node_port
  to_port           = var.node_port
  ip_protocol       = "tcp"
  description       = "NodePort from ALB"
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = var.alb_port
  to_port           = var.alb_port
  ip_protocol       = "tcp"
  description       = "HTTP from Internet to ALB"
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "All outbound"
}

# EC2

resource "aws_instance" "k8s" {
  ami                         = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.this.id]
  key_name                    = aws_key_pair.this.key_name
  associate_public_ip_address = true

  user_data_base64            = data.cloudinit_config.bootstrap.rendered
  user_data_replace_on_change = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name        = "${var.project_name}-ec2"
    Project     = var.project_name
    Environment = "learning"
  }
}

# LOAD BALANCER

resource "aws_lb" "this" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.this.id]
  subnets            = [aws_subnet.public.id, aws_subnet.public_b.id]

  tags = { Name = "${var.project_name}-alb" }
}

resource "aws_lb_target_group" "this" {
  name        = "${var.project_name}-tg"
  port        = var.node_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.this.id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/"
    port                = var.node_port
    protocol            = "HTTP"
    interval            = 15
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
  }

  tags = { Name = "${var.project_name}-tg" }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.alb_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

resource "aws_lb_target_group_attachment" "this" {
  target_group_arn = aws_lb_target_group.this.arn
  target_id        = aws_instance.k8s.id
  port             = var.node_port
}
