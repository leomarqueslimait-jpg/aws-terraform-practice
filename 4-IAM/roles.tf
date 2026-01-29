locals {
  users = ["John", "Jane", "Lauro"]

  role_policy_map = {
    "readonly"  = "arn:aws:iam::aws:policy/ReadOnlyAccess"
    "admin"     = "arn:aws:iam::aws:policy/AdministratorAccess"
    "developer" = "arn:aws:iam::aws:policy/PowerUserAccess"
  }
}

resource "aws_iam_user" "users" {
    for_each = toset(local.users)
    name = each.value
}

resource "aws_iam_role" "roles" {
    for_each = local.role_policy_map
    name = each.key
}