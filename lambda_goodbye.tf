resource "aws_iam_role" "lambda_goodbye" {
  name = "lambda-goodbye-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_goodbye_basic" {
  role       = aws_iam_role.lambda_goodbye.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_cloudwatch_log_group" "lambda_goodbye" {
  name              = "/aws/lambda/goodbye-function"
  retention_in_days = 7
}

data "archive_file" "lambda_goodbye" {
  type        = "zip"
  output_path = "${path.module}/goodbye-function.zip"

  source {
    content  = <<EOF
import json

def lambda_handler(event, context):
    return {
        'statusCode': 200,
        'body': json.dumps('Goodbye from Lambda!')
    }
EOF
    filename = "lambda_function.py"
  }
}

resource "aws_lambda_function" "goodbye" {
  filename         = data.archive_file.lambda_goodbye.output_path
  function_name    = "goodbye-function"
  role             = aws_iam_role.lambda_goodbye.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda_goodbye.output_base64sha256
  runtime          = "python3.12"
  timeout          = 10

  depends_on = [
    aws_iam_role_policy_attachment.lambda_goodbye_basic,
    aws_cloudwatch_log_group.lambda_goodbye,
  ]
}