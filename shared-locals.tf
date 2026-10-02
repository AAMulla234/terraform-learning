locals {
  project       = "My-first-terraform-aws"
  project_owner = "akhtar"
  managed_by    = "Terraform"
}

locals {
  common_tags = {
    ManagedBy    = "Terraform"
    Name         = "${local.project}-${var.project}-${var.alias}-${var.env}"
    Project      = "${var.project}"
    ProjectOwner = local.project_owner
  }
}
