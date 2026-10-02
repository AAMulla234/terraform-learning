
# data "aws_ssm_parameter" "ecs_ami" {
#   name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
# }


data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-22.04-amd64-server-*"]
  }
}

output "ubuntu_ami_data" {
  value = data.aws_ami.ubuntu.id
}

resource "aws_instance" "web" {
  ami                         = data.aws_ami.ubuntu.id
  associate_public_ip_address = true
  instance_type               = var.ec2_instance_type
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.public_http_traffic.id]
  root_block_device {
    delete_on_termination = true
    volume_size           = var.ec2_instance_volume.size
    volume_type           = var.ec2_instance_volume.type
  }
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    ManagedBy = "Terraform Project By Akhtar"
  }
}

# Create EC2 Security Group
resource "aws_security_group" "public_http_traffic" {
  description = "Security group allowing traffic on port 443 and 80"
  vpc_id      = aws_vpc.demo_vpc.id

  tags = merge(local.common_tags, {
    Name = "public-http-sg-${var.project}-${var.alias}-${var.env}"
  })

}

# Ingress rule - Inbound rule for http request for port 80
resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.public_http_traffic.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"

}

# Ingress rule - Inbound rule for https request for port 443
resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.public_http_traffic.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}