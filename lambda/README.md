# Creating a Lambda Function in Terraform

## What I Learned

This document captures my learning journey of creating an AWS Lambda function with all the necessary IAM roles using Terraform.

## Step 1: Zipping the Lambda Function Code

We are going to create a data block that will zip our lambda python from `index.py` into a new zip folder.

```hcl
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.root}/index.py"
  output_path = "${path.root}/lambda_function.zip"
}
```

## Step 2: Understanding IAM Policies - Trust Policy vs Permission Policy

Instead of making `resource "aws_iam_role_policy"` and having to write json document in the middle of terraform, we can use a data block and write the Assume Role policy in the Terraform native language.

### Trust Policy (Assume Role Policy)

This data block is a **Trust Policy** that states that lambda functions in our account can assume roles. This says: "The Lambda service is allowed to assume (use) this role."

```hcl
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}
```

**Key Concept:** The Trust Policy controls **who can use the role**, while the Permission Policy controls **what the role can do**.

## Step 3: Fetching the Permission Policy

Instead of hard coding the arn in `resource "aws_iam_role_policy_attachment"`, we can make a data block that fetches the policy document from AWS. This is the permission which states: "What can this role do once it's being used?"

```hcl
data "aws_iam_policy" "lambda_execution" {
  name = "AWSLambdaBasicExecutionRole"
}
```

This fetches the AWS-managed policy `AWSLambdaBasicExecutionRole` which allows Lambda to write logs to CloudWatch.

## Step 4: Creating the IAM Role

Now we create the role that the lambda function can use.

```hcl
resource "aws_iam_role" "lambda_role" {
  name               = "role_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}
```

## Step 5: Attaching the Permission Policy to the Role

This resource is what connects the role to the permission policy (`aws_iam_role_policy_attachment` states that `role = aws_iam_role.lambda_role.name` is connected to the permission Policy).

```hcl
resource "aws_iam_role_policy_attachment" "lambda_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = data.aws_iam_policy.lambda_execution.arn
}
```

## Step 6: Creating the Lambda Function

This is the function itself.

```hcl
resource "aws_lambda_function" "my_function" {
  filename         = "lambda_function.zip"
  function_name    = "lambda_function"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  depends_on = [aws_iam_role_policy_attachment.lambda_execution]
}
```

## Step 7: Creating a Public Function URL

Create a public Function URL for the Lambda, so you can access it using a url.

```hcl
resource "aws_lambda_function_url" "function_url" {
  function_name      = aws_lambda_function.my_function.function_name
  authorization_type = "NONE"

  cors {
    allow_origins  = ["*"]
    allow_methods  = ["GET", "POST"]
    allow_headers  = ["*"]
    expose_headers = ["*"]
    max_age        = 86400
  }
}
```

## Key Takeaways

1. **Two Types of IAM Policies:**
   - **Trust Policy (assume_role_policy):** Controls who can use the role
   - **Permission Policy:** Controls what the role can do

2. **Use Terraform Data Sources Instead of JSON:** Use `data "aws_iam_policy_document"` to write policies in Terraform native language instead of embedding JSON strings.

3. **Fetch AWS-Managed Policies:** Use `data "aws_iam_policy"` to fetch AWS-managed policies by name instead of hard-coding ARNs.

4. **Function URLs Auto-Create Permissions:** When creating a function URL with `authorization_type = "NONE"`, Terraform automatically creates the necessary permissions.

## Running the Configuration

```bash
terraform init
terraform plan
terraform apply
```

Then test your function URL:
```bash
terraform output function_url
curl <your-function-url>
```
