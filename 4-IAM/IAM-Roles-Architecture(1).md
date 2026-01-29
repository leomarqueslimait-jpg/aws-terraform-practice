# AWS IAM Roles & Users Architecture

This Terraform configuration demonstrates the creation and management of AWS IAM users, roles, and their associated policies using modern Terraform techniques including `for_each` loops and dynamic resource creation.

---

## Architecture Overview

This implementation creates a complete IAM setup where:
- Multiple users are created from a centralized list
- Roles are defined with specific AWS managed policies
- All users can assume all roles (simplified for learning purposes)
- User login credentials are generated automatically

---

## Step 1: Define Users and Roles

Instead of hard coding every user, we use a local to store both users and roles. This role will also map directly to the resource.

```hcl
locals {
  users = ["John", "Jane", "Lauro"]

  role_policy_map = {
    "auditor"   = "arn:aws:iam::aws:policy/ReadOnlyAccess"
    "admin"     = "arn:aws:iam::aws:policy/AdministratorAccess"
    "developer" = "arn:aws:iam::aws:policy/PowerUserAccess"
  }
}
```

**Key Learning:** Using locals allows for centralized configuration management and easier maintenance.

---

## Step 2: Create IAM Users

We create users by using the `for_each` argument to create users using the `local.users` keys. Since `local.users` is a list, we need to use `toset` to convert it into a map. We could use either `each.value` or `each.key`.

```hcl
resource "aws_iam_user" "users" {
  for_each = toset(local.users)
  name     = each.value
}
```

**Key Learning:** `toset()` converts a list into a set, making it compatible with `for_each`.

---

## Step 3: Create IAM Roles

We need to create the roles. We use `for_each` to iterate and extract the keys from `local.role_policy_map` and create a role where the attribute "name" is the key of each item. We use `assume_role_policy` to state who can assume the role.

```hcl
resource "aws_iam_role" "roles" {
  for_each           = local.role_policy_map
  name               = each.key
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}
```

### Understanding `each.key` and `each.value` in `for_each`

When iterating over `local.role_policy_map`:

**Iteration 1:**
- `each.key` = "auditor"
- `each.value` = "arn:aws:iam::aws:policy/ReadOnlyAccess"
- → Creates role named "auditor"

**Iteration 2:**
- `each.key` = "admin"
- `each.value` = "arn:aws:iam::aws:policy/AdministratorAccess"
- → Creates role named "admin"

**Iteration 3:**
- `each.key` = "developer"
- `each.value` = "arn:aws:iam::aws:policy/PowerUserAccess"
- → Creates role named "developer"

---

## Step 4: Define Assume Role Policy

Here is where we define who can assume these roles. For now, to simplify learning this concept, we will make it so that everyone can assume all the roles.

The `data "aws_iam_policy_document"` attaches each role to a user. In `identifiers`, we need to fetch the `.arn` attribute. It is with `.arn` that Amazon can work with it.

```hcl
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [for user in aws_iam_user.users : user.arn]
    }
  }
}
```

**Key Learning:** The `identifiers` list uses a `for` expression to dynamically collect all user ARNs.

---

## Step 5: Attach Policies to Roles

Now we need to give each role the permissions. So far, the roles are just empty containers. We use a `for_each` argument to iterate over the roles created in `aws_iam_role.roles` and identify the name of each role. We then assign the `policy_arn` with `each.value` of the map already declared in `local.role_policy_map`.

```hcl
resource "aws_iam_role_policy_attachment" "policy_attachment" {
  for_each   = local.role_policy_map
  role       = aws_iam_role.roles[each.key].name
  policy_arn = each.value
}
```

**Key Learning:** This creates the actual permissions by attaching AWS managed policies to each role.

---

## Step 6: Create User Login Profiles

We need to create passwords for each user so they can actually log in to their profiles. `aws_iam_user_login_profile` creates a randomized password. We use `for_each` again to assign a password to each user created with `aws_iam_user.users`.

```hcl
resource "aws_iam_user_login_profile" "users" {
  for_each        = aws_iam_user.users
  password_length = 8
  user            = each.value.name
}
```

---

## Step 7: Output User Passwords

The output here will give the password of each user so we can log in. We use a `for` loop where `profile` will return the value of each `.password` created in `aws_iam_user_login_profile.users`. This password is stored in `user`.

```hcl
output "passwords" {
  sensitive = true
  value = {
    for user, profile in aws_iam_user_login_profile.users :
    user => profile.password
  }
}
```

**Key Learning:** The `sensitive = true` flag prevents passwords from being displayed in plain text in the Terraform output.

---

## Resources Created

| Resource Type | Count | Description |
|--------------|-------|-------------|
| IAM Users | 3 | John, Jane, Lauro |
| IAM Roles | 3 | auditor, admin, developer |
| Login Profiles | 3 | One per user with auto-generated password |
| Role Policy Attachments | 3 | Connects managed policies to roles |

---

## Key Terraform Concepts Demonstrated

- **`for_each`** - Iterating over maps and sets to create multiple resources
- **`toset()`** - Converting lists to sets for `for_each` compatibility
- **`each.key` and `each.value`** - Accessing map elements during iteration
- **`locals`** - Centralizing configuration data
- **`for` expressions** - Creating lists and maps dynamically
- **Data sources** - Using `aws_iam_policy_document` to generate policies
- **Resource references** - Linking resources together (e.g., `aws_iam_role.roles[each.key].name`)
- **Sensitive outputs** - Protecting sensitive data in outputs

---

## Usage

To retrieve user passwords after applying:

```bash
terraform output -json passwords
```

---

## Notes

- This configuration is simplified for learning purposes
- In production, you would implement least privilege access
- Consider using AWS Organizations and more granular role assumptions
- Passwords should be rotated and managed securely
