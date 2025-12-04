variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "lotr-chatbot"
}

variable "embedding_model_id" {
  type        = string
  description = "E.g., amazon.titan-embed-text-v2:0"
  default     = "amazon.titan-embed-text-v2:0"
}

variable "bedrock_model_id" {
  type    = string
  default = "anthropic.claude-sonnet-4-20250514-v1:0"
}
