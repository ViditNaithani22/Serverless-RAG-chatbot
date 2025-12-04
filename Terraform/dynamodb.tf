
# ============================================
# DYNAMODB TABLES
# ============================================

# ChatbotSessions Table
resource "aws_dynamodb_table" "chatbot_sessions" {
  name         = "${var.project_name}-ChatbotSessions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"

  attribute {
    name = "userId"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = {
    Name = "${var.project_name}-sessions-table"
  }
}

# ChatbotRateLimits Table
resource "aws_dynamodb_table" "chatbot_rate_limits" {
  name         = "${var.project_name}-ChatbotRateLimits"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "identifier"

  attribute {
    name = "identifier"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = {
    Name = "${var.project_name}-rate-limits-table"
  }
}


output "dynamodb_sessions_table" {
  value       = aws_dynamodb_table.chatbot_sessions.name
  description = "DynamoDB sessions table name"
}

output "dynamodb_rate_limits_table" {
  value       = aws_dynamodb_table.chatbot_rate_limits.name
  description = "DynamoDB rate limits table name"
}
