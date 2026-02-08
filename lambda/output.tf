output "function_url" {
  value       = aws_lambda_function_url.function_url.function_url
  description = "The HTTPS endpoint for Lambda"
}