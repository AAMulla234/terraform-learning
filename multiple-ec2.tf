locals {
  ami_ids = {
    ubuntu = data.aws_ami.ubuntu.id
    nginx  = data.aws_ami.nginx.id
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "nginx" {
  most_recent = true

  filter {
    name   = "name"
    values = ["bitnami-nginx-1.29.0-*-linux-debian-12-x86_64-hvm-ebs-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


resource "aws_instance" "multiple-ec" {
  count         = length(var.ec2_instance_config_list)
  ami           = local.ami_ids[var.ec2_instance_config_list[count.index].ami]
  instance_type = var.ec2_instance_config_list[count.index].instance_type
  subnet_id     = aws_subnet.main_dc[count.index % length((aws_subnet.main_dc))].id

  tags = {
    "Name" = "contact-dc-${var.ec2_instance_config_list[count.index].ami}-${count.index + 1}"
  }
}


#  Create EC2 multiple instances using Map object
# resource "aws_instance" "multiple-ec-map" {
#     for_each =  var.ec2_instance_config_map
#     ami =   local.ami_ids[each.value.ami]
#     instance_type = each.value.instance_type

#     subnet_id     = aws_subnet.main[0].id

#   tags = {
#     "Name" = "contact-dc-${each.value.ami}"
#   }
# }


output "ubuntu_ami_data" {
  value = data.aws_ami.ubuntu.id
}

output "nginx_ami_data" {
  value = data.aws_ami.nginx.id
}