terraform {
  required_version = "~> 1.7"

  # A backend in Terraform defines how and where the Terraform state file (terraform.tfstate) is stored.
  # By default, it's stored locally in your project directory, but in a team environment, that’s risky
  backend "s3" {
    bucket  = "${var.project}-${var.alias}-${var.env}-${var.slice}-${var.region}"
    key     = "contact-infrastructure.tfstate"
    region  = var.region
    encrypt = "true"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Terraform   = "True"
      Environment = var.env
      Owner       = "Contact"
      Project     = var.project
      ManagedBy   = "Terraform"
      costCentre  = "contact"
      Lifecycle   = var.account_lifecycle
    }
  }
}

#--------------------------------------------------------------
# Account Rules
#--------------------------------------------------------------

data "aws_caller_identity" "current" {
}

data "aws_availability_zones" "available" {
  state = "available"
}

output "aws_caller_identity" {
  value = data.aws_caller_identity.current
}

output "azs" {
  value = data.aws_availability_zones.available
}