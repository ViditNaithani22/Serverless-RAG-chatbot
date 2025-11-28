
#S3 bucket - frontend
# upload the chat-bot-ui.html file present in this repository's "Frontend" folder after the bucket creation

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}


resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project_name}-frontend-${random_string.suffix.result}"

  tags = {
    Name = "${var.project_name}-frontend"
  }
}


resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "chat-bot-ui.html"
  }

  error_document {
    key = "chat-bot-ui.html"
  }
}

# giving access to cloudfront for this S3 bucket
resource "aws_s3_bucket_policy" "frontend_policy" {
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action = "s3:GetObject"
        Resource = [
          "${aws_s3_bucket.frontend.arn}/*"
        ]
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.frontend.arn
          }
        }
      }
    ]
  })
}


#S3 bucket - backend
# upload your PDF files after the bucket creation

resource "aws_s3_bucket" "backend" {
  bucket = "${var.project_name}-backend-${random_string.suffix.result}"

  tags = {
    Name = "${var.project_name}-backend"
  }
}


