# IAM role for EC2 to join ECS cluster
resource "aws_iam_role" "ecs_instance_role" {
    name = "akhtar-ecsInstanceRole"

    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [{
        Effect = "Allow",
        Principal = {
            Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
        }]
  })
}

# Attach role policy
resource "aws_iam_role_policy_attachment" "ecs_instance_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# Crate profile that attach to Iam role
resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "akhtar-ecsInstanceProfile"
  role = aws_iam_role.ecs_instance_role.name
}

# Key pair can be used to do ssh
resource "aws_key_pair" "ecs_key" {
  key_name   = "akhtar-ecs-key" 
  public_key = file("/home/gs-6610/.ssh/akhtar-ecs-key.pub")
}

# ECS Cluster
resource "aws_ecs_cluster" "first-ecs_cluster" {
  name = "first-ecs-nginx-ec2-cluster"
}

# Security group for EC2/ECS container instances
resource "aws_security_group" "first-ecs_instance_sg" {
  name        = "first-ecs-instance-sg"
  vpc_id      = aws_vpc.demo_vpc.id
  description = "Allow SSH and intra-VPC traffic"

  # Allows incoming SSH connections on port 22 from any IP address
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # restrict in production!
  }

  # incoming all TCP traffic (ports 0 to 65535) from within your VPC (10.0.0.0/16).
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.demo_vpc.cidr_block]
  }

  #  Allows all outbound traffic to anywhere -  This lets the ECS EC2 instances pull container images, 
  # communicate with AWS ECS control plane, or access external APIs.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Get latest ECS-optimized AMI(Amazon Machine Image)
# Go AWS system Manager and search Paramter for ECS - AWS recommended AMI image
# It  is build Amazon linux 2 AMIs that includes: Docker, ECS Agent - automatically join to your ECS cluster, kurnel tunning ECS
data "aws_ssm_parameter" "ecs_ami" {
   name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

# Launch template
resource "aws_launch_template" "ecs_launch_template" {
    name_prefix = "ecs-nginx-"
    image_id = data.aws_ssm_parameter.ecs_ami.value
    instance_type = "t3.micro"

    iam_instance_profile {
      name = aws_iam_instance_profile.ecs_instance_profile.name
    }

    key_name = aws_key_pair.ecs_key.key_name

    network_interfaces {
      associate_public_ip_address = true
      security_groups = [aws_security_group.first-ecs_instance_sg.id]
    }

    user_data = base64encode(<<-EOF
              #!/bin/bash
              echo ECS_CLUSTER=${aws_ecs_cluster.first-ecs_cluster.name} >> /etc/ecs/ecs.config
              EOF
    )
}

# Auto Scaling Group
resource "aws_autoscaling_group" "ecs_asg" {
  name                      = "ecs-asg"
  desired_capacity          = 1
  max_size                  = 2
  min_size                  = 1
  vpc_zone_identifier       = [aws_subnet.public_subnet.id]
  health_check_type         = "EC2"
  launch_template {
    id      = aws_launch_template.ecs_launch_template.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "first-ecs-container-instance"
    propagate_at_launch = true
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "first-nginx_task" {
  family                   = "nginx-ec2-task"
  requires_compatibilities = ["EC2"]
  network_mode            = "bridge"
  cpu                     = "256"
  memory                  = "512"

  container_definitions = jsonencode([
    {
      name      = "nginx"
      image     = "nginx:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}

# ECS Service
resource "aws_ecs_service" "first-nginx_service" {
  name            = "nginx-ec2-service"
  cluster         = aws_ecs_cluster.first-ecs_cluster.id
  task_definition = aws_ecs_task_definition.first-nginx_task.arn
  desired_count   = 1
  launch_type     = "EC2"
}

