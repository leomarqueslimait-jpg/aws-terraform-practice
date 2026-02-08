data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.root}/index.py"
  output_path = "${path.root}/lambda_function.zip"
}

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

data "aws_iam_policy" "lambda_execution" {
  name = "AWSLambdaBasicExecutionRole"
}


resource "aws_iam_role" "lambda_role" {
  name               = "role_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}
 
resource "aws_iam_role_policy_attachment" "lambda_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = data.aws_iam_policy.lambda_execution.arn
}

resource "aws_lambda_function" "my_function" {
  filename         = "lambda_function.zip"
  function_name    = "lambda_function"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  depends_on = [aws_iam_role_policy_attachment.lambda_execution]
}

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
