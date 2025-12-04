# ============================================
# HTTP API GATEWAY
# ============================================

# Create HTTP API Gateway
resource "aws_apigatewayv2_api" "chatbot_api" {
  name          = "${var.project_name}-api"
  protocol_type = "HTTP"
  description   = "HTTP API Gateway for chatbot Lambda function"

  cors_configuration {
    allow_origins  = ["*"]
    allow_methods  = ["POST", "OPTIONS"]
    allow_headers  = ["content-type"]
    expose_headers = ["*"]
    max_age        = 3600
  }

  tags = {
    Name = "${var.project_name}-api"
  }
}

# Create API Gateway Stage (default stage)
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.chatbot_api.id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    throttling_burst_limit = 20
    throttling_rate_limit  = 10
  }

  tags = {
    Name = "${var.project_name}-api-stage"
  }
}

# Create Lambda Integration
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.chatbot_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.chatbot.invoke_arn

  integration_method     = "POST"
  payload_format_version = "2.0"

  description = "Lambda integration for chatbot"
}

# Create POST route
resource "aws_apigatewayv2_route" "post_route" {
  api_id    = aws_apigatewayv2_api.chatbot_api.id
  route_key = "POST /chat"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Create OPTIONS route (for CORS preflight)
resource "aws_apigatewayv2_route" "options_route" {
  api_id    = aws_apigatewayv2_api.chatbot_api.id
  route_key = "OPTIONS /chat"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Grant API Gateway permission to invoke Lambda
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.chatbot.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.chatbot_api.execution_arn}/*/*/chat"
}

# ============================================
# OUTPUTS
# ============================================

output "api_gateway_url" {
  value       = "${aws_apigatewayv2_api.chatbot_api.api_endpoint}/chat"
  description = "API Gateway endpoint URL for POST requests"
}

output "api_gateway_id" {
  value       = aws_apigatewayv2_api.chatbot_api.id
  description = "API Gateway ID"
}

output "api_gateway_endpoint" {
  value       = aws_apigatewayv2_api.chatbot_api.api_endpoint
  description = "API Gateway base endpoint"
}
