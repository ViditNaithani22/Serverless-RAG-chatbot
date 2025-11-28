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
  default     = "cohere.embed-english-v3"
}

variable "bedrock_model_id" {
  type    = string
  default = "anthropic.claude-3-sonnet-20240229-v1:0"
}
