variable "project" {
  description = "Project (e.g. contact)"
  default     = "contact"
}

variable "region" {
  description = "Region alias (e.g. in)"
  type        = string
  default     = "ap-south-1"
}

variable "alias" {
  description = "AWS Region alias (e.g. in)"
  default     = "in"
}

variable "slice" {
  description = "Current slice (e.g s1)"
  default     = "s1"
}

variable "env" {
  description = "Environment (for this repo this should be main)"
  default     = "dev"
}

variable "account_lifecycle" {
  description = "Is the Account a development account for power saving?"
  default     = "live"
}

variable "profile" {
  description = "AWS CLI profile name"
  type        = string
  default     = "default"
}

variable "vpc_cidr" {
  default = "10.100.0.0/16" // dev, uat and prd can use same cidr range 
}

variable "dc_subnet_cidrs" {
  description = "Subnet CIDR ranges per env/slice allocated."
  default = {
    "dev" = {
      "s1" = [
        "10.100.0.0/24", // Subnet 1 for dev-s1
        "10.100.1.0/24", // Subnet 2 for dev-s1
        "10.100.2.0/24"  // Subnet 3 for dev-s1
      ],
      "s2" = [
        "10.100.10.0/24", // Subnet 1 for dev-s2
        "10.100.11.0/24", // Subnet 2 for dev-s2
        "10.100.12.0/24"  // Subnet 3 for dev-s2
      ]
    },
    "uat" = {
      "s1" = [
        "10.100.20.0/24", // Subnet 1 for uat-s1
        "10.100.21.0/24", // Subnet 2 for uat-s1
        "10.100.22.0/24"  // Subnet 3 for uat-s1
      ],
      "s2" = [
        "10.100.30.0/24", // Subnet 1 for uat-s2
        "10.100.31.0/24", // Subnet 2 for uat-s2
        "10.100.32.0/24"  // Subnet 3 for uat-s2
      ]
    }
  }
}


variable "use_direct_connect" {
  default = true // override in deployment variables
}

variable "bucket_name" {
  type        = string
  description = "My first static website-akhtar"
  default     = "my-static-website-akhtar"
}

variable "ec2_instance_type" {
  type        = string
  default     = "t2.micro"
  description = "EC2 instance managed by AWS - default is t2.micro"

  validation {
    # condition = var.ec2_instance_type == "t2.micro" || var.ec2_instance_type == "t3.micro"
    condition     = contains(["t2.micro", "t3.micro"], var.ec2_instance_type)
    error_message = "Only support t2.micro or t3.micro"
  }
}


variable "ec2_instance_config_list" {
  type = list(object({
    instance_type = string
    ami           = string
  }))

  validation {
    condition = alltrue([
      for config in var.ec2_instance_config_list : contains(["t2.micro"], config.instance_type)
    ])
    error_message = "Only t2.micro instance are allowed."
  }

  validation {
    condition = alltrue([
      for config in var.ec2_instance_config_list : contains(["nginx", "ubuntu"], config.ami)
    ])
    error_message = "At least one of the provided \"ami\" values is not supported.\nSupported \"ami\" values: \"ubuntu\", \"nginx\"."
  }

  default = []
}

variable "ec2_instance_config_map" {
  type = map(object({
    instance_type = string
    ami           = string
  }))
}


# variable "ec2_instance_volume" {
#   type = object({
#     size = number
#     type = string
#   })
#   description = "EC2 instance volume type and size"
# }

# variable "additional_tags" {
#   type = map(string)
# }

