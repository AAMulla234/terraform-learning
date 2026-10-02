data "aws_ami" "ubuntu" {
  most_recent = true
  owners = ["099720109477"]

  filter {
    name ="name"
    values =  ["ubuntu/images/hvm-ssd/ubuntu-*-22.04-amd64-server-*"]
  }
}

output "ubuntu_ami_data" {
  value = data.aws_ami.ubuntu.id
}

resource "aws_instance" "web" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  root_block_device {
    delete_on_termination = true
    volume_size = 10
    volume_type = "gp3"
  }

}
