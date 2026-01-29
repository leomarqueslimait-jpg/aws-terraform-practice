locals {
  users = ["John", "Jane", "Lauro"]

  role_policy_map = {
    "auditor"   = "arn:aws:iam::aws:policy/ReadOnlyAccess"
    "admin"     = "arn:aws:iam::aws:policy/AdministratorAccess"
    "developer" = "arn:aws:iam::aws:policy/PowerUserAccess"
  }
}

resource "aws_iam_user" "users" {
  for_each = toset(local.users)
  name     = each.value
}

resource "aws_iam_role" "roles" {
  for_each           = local.role_policy_map
  name               = each.key
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json

}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [for user in aws_iam_user.users : user.arn]
    }
  }
}


resource "aws_iam_role_policy_attachment" "policy_attachment" {

  for_each   = local.role_policy_map
  role       = aws_iam_role.roles[each.key].name
  policy_arn = each.value

}

resource "aws_iam_user_login_profile" "users" {
  for_each = aws_iam_user.users
  password_length = 8
  user = each.value.name
}

output "passwords" {
  sensitive = true
  value = {
    for user, profile in aws_iam_user_login_profile.users :
    user => profile.password
  }
}