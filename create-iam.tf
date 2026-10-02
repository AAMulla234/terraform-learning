locals {
  users_from_yaml = yamldecode(file("users.yaml")).users
  users_map = {
    for user_config in local.users_from_yaml : user_config.username => user_config.roles...
  }
  flattend_users_map = {
    for user, roles in local.users_map : user => flatten(roles)
  }
}

resource "aws_iam_user" "users" {
  for_each = toset(local.users_from_yaml[*].username)
  name     = each.value
}

resource "aws_iam_user_login_profile" "users" {
  for_each        = aws_iam_user.users
  user            = each.value.name
  password_length = 8

  lifecycle {
    ignore_changes = [
      password_length,
      password_reset_required,
      pgp_key
    ]
  }
}

output "users" {
  value = local.flattend_users_map
}

output "passwords" {
  sensitive = true
  value = {
    for user, user_login in aws_iam_user_login_profile.users : user => user_login.password
  }
}