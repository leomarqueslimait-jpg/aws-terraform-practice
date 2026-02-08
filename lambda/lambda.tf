#1- we are going to create a data block that will zip our lambda python from index.py into a new zip folder
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.root}/index.py"
  output_path = "${path.root}/lambda_function.zip"
}
/* 2 - Instead of making resource "aws_iam_role_policy" and having to
write json document in the middle of terraform, we can use the below data 
block and write the  Assume Role policy in the Terraform native language
This data block is a Trust Policy that states that  lambda functions in our account can assume roles. 
This says: "The Lambda service is allowed to assume (use) this role."
resource "aws_iam_role_policy_attachment" just states that role = aws_iam_role.lambda_role.name
is connected to the permission Policy
*/
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
# 3- Instead of hard coding the arn in resource "aws_iam_role_policy_attachment",
#we can make a data block that fecthes the policy document from AWS. This is the
#permission which states can What can this role do once it's being used?
data "aws_iam_policy" "lambda_execution" {
  name = "AWSLambdaBasicExecutionRole"
}

#4- now we create the role that the lambda function can use
resource "aws_iam_role" "lambda_role" {
  name               = "role_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}
#5- this resource is what connect the role to the trust policy. 
resource "aws_iam_role_policy_attachment" "lambda_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = data.aws_iam_policy.lambda_execution.arn
}
#6 - this is the function itself
resource "aws_lambda_function" "my_function" {
  filename         = "lambda_function.zip"
  function_name    = "lambda_function"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  depends_on = [aws_iam_role_policy_attachment.lambda_execution]
}
#7 - # Create a public Function URL for the Lambda, so you can access it using an url
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
