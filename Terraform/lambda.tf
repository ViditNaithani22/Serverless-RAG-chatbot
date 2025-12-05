# ============================================
# LAMBDA FUNCTION
# ============================================

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role"

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

  tags = {
    Name = "${var.project_name}-lambda-role"
  }
}

# Attach basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# IAM Policy for Lambda to access Lex and DynamoDB
resource "aws_iam_role_policy" "lambda_permissions" {
  name = "${var.project_name}-lambda-permissions"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lex:RecognizeText",
          "lex:RecognizeUtterance",
          "lex:StartConversation"
        ]
        Resource = [
          "arn:aws:lex:${var.aws_region}:${data.aws_caller_identity.current.account_id}:bot-alias/${aws_lexv2models_bot.chatbot.id}/*",
          "arn:aws:lex:${var.aws_region}:${data.aws_caller_identity.current.account_id}:bot/${aws_lexv2models_bot.chatbot.id}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem"
        ]
        Resource = aws_dynamodb_table.chatbot_sessions.arn
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem"
        ]
        Resource = aws_dynamodb_table.chatbot_rate_limits.arn
      }
    ]
  })
}


# Create a ZIP file for Lambda function code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/index.mjs"
  output_path = "${path.module}/lambda_function.zip"
}

# Lambda Function
resource "aws_lambda_function" "chatbot" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-lambda"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "nodejs20.x"
  timeout          = 30
  memory_size      = 256

  environment {
    variables = {
      BOT_ID                  = aws_lexv2models_bot.chatbot.id
      BOT_ALIAS_ID            = "TSTALIASID"
      LOCALE_ID               = "en_US"
      SESSIONS_TABLE          = aws_dynamodb_table.chatbot_sessions.name
      RATE_LIMIT_TABLE        = aws_dynamodb_table.chatbot_rate_limits.name
      MAX_REQUESTS_PER_MINUTE = "10"
    }
  }

  tags = {
    Name = "${var.project_name}-lambda"
  }

  depends_on = [
    aws_iam_role_policy.lambda_permissions,
    aws_iam_role_policy_attachment.lambda_basic,
    null_resource.build_bot_locale,
    aws_dynamodb_table.chatbot_sessions,
    aws_dynamodb_table.chatbot_rate_limits
  ]
}



# ============================================
# OUTPUTS
# ============================================

output "lambda_function_name" {
  value       = aws_lambda_function.chatbot.function_name
  description = "Lambda function name"
}

output "lambda_function_arn" {
  value       = aws_lambda_function.chatbot.arn
  description = "Lambda function ARN"
}


