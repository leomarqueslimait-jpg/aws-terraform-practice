/* we 
*/
locals {
  users = ["John", "Jane", "Lauro"]

  role_policy_map = {
    "auditor"   = "arn:aws:iam::aws:policy/ReadOnlyAccess"
    "admin"     = "arn:aws:iam::aws:policy/AdministratorAccess"
    "developer" = "arn:aws:iam::aws:policy/PowerUserAccess"
  }
}
resource "aws_iam_user_login_profile" "users" {
  for_each = aws_iam_user.users
  password_length = 8
  user = each.value.name
}

resource "aws_iam_user" "users" {
  for_each = toset(local.users)
  name     = each.value
}
# creates the role. We use for_each to extract the keys from local.role_policy_map and create a role where name is the key of each item.
#Use assume_role_policy to state what is the policy of each role.
resource "aws_iam_role" "roles" {
  for_each           = local.role_policy_map
  name               = each.key
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json

}
# data "aws_iam_policy_document" attaches each role to a user. In identifies we need to fetch the .arn attribute. It is with .arn that Amazon work with it
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


output "passwords" {
  sensitive = true
  value = {
    for user, profile in aws_iam_user_login_profile.users :
    user => profile.password
  }
}