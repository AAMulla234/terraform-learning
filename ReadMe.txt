Setup AWS access key default to environment permanantly. it is optional. you should .env

Create a file ~/.aws/credentials and add:

[default]
aws_access_key_id = your-access-key
aws_secret_access_key = your-secret-key
region = us-east-1

Creating VPCs and Subnets

-> VPC a logic separate infrasture where you have your resources separated from others 
-> Subnet : Public and Private Subnet
-> Public subnet with IGW interet gateway to talk Public
-> private subnet: resources don't want to talk outside
-> deploy an EC2 instance inside of the created subnet
-> Associate a public IP and a security group that allows public ingress

Gateways
    - Internet Gateway
    - Transite Gateway

Backends
    - S# bucket as backends that helps to create the terraform state files those can be store to S3 and not local

S3:
    create-s3 also have a exercise to create static web-site using terraform

Data source Query:



Meta-arguments:

    - depends_on: used to explicitly define dependencies between resources
    - count and for_each:allow to creation of same resource type multiples
    - provider: which provider to use with specific resource
    - lifecycle:
        - create_before_destroy: Prevent terraform default behavior, destroy before create resource. The behaviour is propogate to chile resources
        - Prevent_destroy: terraform exist with error if planned changes would lead to the destruction of the resource marked with this
        - replace_triggered_by: replace the deplendent resource when any referenced item changes
        - ignore_changes: we can provide list of attributes that should not trigger an update when modified outside terraform 

Locals
    locals {
        math       = 2 * 2 // *. /, +, -
        equality   = 2 != 2  // ==, !=
        comparison = 2 < 1 / < , >, <=,   =<
        logical    = true || false
    }

variable "object_list" {
    type = list(object({
        firstName = string
        lastName = string
    }))
}

terraform.tfvars

    object_list = [
        {
            firstName = "akhtar"
            lastName = "qureshi"
        },
        {
            firstName = "akhtar"
            lastName = "mulla"
        }
    ]


any.tf

locals {
    fullnames = [ for person in var.object_list : "${person.firstName} ${person.lastName}"]
}

output  "person_output"{
    value = local.fullnames
}
--------------------------------------------------
Map

variable "numbers_map" {
  type = map(number)
}

terraform.tfvars

numbers_map {
    "One" = 1
    "Two" = 2
    "Three" = 3
}

locals {
    temp_map = {for key, value in var.numbers_map : key => value * 2 }
}

output "print" {
   value = locals.temp_map
}


list to map
locals {
    usermap = {
        for user_info in var.users : user_info.username => {role = user_info.roles }...
    }
}


-------------------------------------------------------------
splat expression - only allow to use for list. not support for map

locals {
    firstName_from_splat = var.object_list[*].firstName
}


----------------------------------------------------------
function to read file

output "output_File" {
    value = yamldecode(file("${path.module}/users.yaml")).users
}

------------------------------------------------------
Round robin pattern apply to deploy EC2 instances to available subnets

subnet_id = aws_subnet.main[count.index % length(aws_subnet.main)].index

#   0 % 2 = 0
#   1 % 2 = 1
#   2 % 2 = 0
#   3 % 2 = 1