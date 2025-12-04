# ============================================
# AMAZON LEX BOT - WITH BEDROCK KB INTEGRATION
# ============================================

# IAM Role for Lex Bot
resource "aws_iam_role" "lex_bot_role" {
  name = "${var.project_name}-lex-bot-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lexv2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-lex-bot-role"
  }
}

# IAM Policy for Lex to access Bedrock KB directly
resource "aws_iam_role_policy" "lex_bedrock_policy" {
  name = "${var.project_name}-lex-bedrock-policy"
  role = aws_iam_role.lex_bot_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:Retrieve",
          "bedrock:RetrieveAndGenerate"
        ]
        Resource = aws_bedrockagent_knowledge_base.main.arn
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel"
        ]
        Resource = [
          "arn:aws:bedrock:${var.aws_region}::foundation-model/${var.bedrock_model_id}",
          "arn:aws:bedrock:${var.aws_region}::foundation-model/${var.embedding_model_id}"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:GetFoundationModel",
          "bedrock:ListFoundationModels"
        ]
        Resource = "*"
      }
    ]
  })
}

# Lex Bot
resource "aws_lexv2models_bot" "chatbot" {
  name     = "${var.project_name}-bot"
  role_arn = aws_iam_role.lex_bot_role.arn

  idle_session_ttl_in_seconds = 300

  data_privacy {
    child_directed = false
  }

  tags = {
    Name = "${var.project_name}-bot"
  }

  depends_on = [
    aws_iam_role_policy.lex_bedrock_policy
  ]
}

# Bot Locale (English US)
resource "aws_lexv2models_bot_locale" "en_us" {
  bot_id      = aws_lexv2models_bot.chatbot.id
  bot_version = "DRAFT"
  locale_id   = "en_US"

  n_lu_intent_confidence_threshold = 0.40

  voice_settings {
    voice_id = "Joanna"
  }
}

# ============================================
# INTENT 1: WELCOME INTENT
# ============================================

resource "aws_lexv2models_intent" "welcome" {
  bot_id      = aws_lexv2models_bot.chatbot.id
  bot_version = "DRAFT"
  locale_id   = aws_lexv2models_bot_locale.en_us.locale_id
  name        = "WelcomeIntent"

  description = "Responds to greetings"

  # Sample utterances
  sample_utterance {
    utterance = "Hi"
  }

  sample_utterance {
    utterance = "Hello"
  }

  sample_utterance {
    utterance = "Hey"
  }

  sample_utterance {
    utterance = "Good morning"
  }

  sample_utterance {
    utterance = "Good afternoon"
  }

  # Initial response (greeting response)
  initial_response_setting {
    initial_response {
      message_group {
        message {
          plain_text_message {
            value = "Hi, how can I help you today?"
          }
        }
      }
    }
  }
}



# ============================================
# INTENT 2: QNA INTENT (BEDROCK KB - BUILT-IN)
# ============================================
# Note: Terraform doesn't support QnAIntentConfiguration, so we create 
# the entire intent using AWS CLI with a JSON file

# Create JSON file for QnA intent configuration
resource "local_file" "qna_intent_config" {
  filename = "${path.module}/qna-intent.json"
  content = jsonencode({
    botId                 = aws_lexv2models_bot.chatbot.id
    botVersion            = "DRAFT"
    localeId              = aws_lexv2models_bot_locale.en_us.locale_id
    intentName            = "QnAIntent"
    description           = "Answers questions using Bedrock Knowledge Base"
    parentIntentSignature = "AMAZON.QnAIntent"
    qnAIntentConfiguration = {
      dataSourceConfiguration = {
        bedrockKnowledgeStoreConfiguration = {
          bedrockKnowledgeBaseArn = aws_bedrockagent_knowledge_base.main.arn
        }
      }
      bedrockModelConfiguration = {
        modelArn = "arn:aws:bedrock:${var.aws_region}::foundation-model/${var.bedrock_model_id}"
      }
    }
  })
}

resource "null_resource" "create_qna_intent" {
  depends_on = [
    aws_lexv2models_bot_locale.en_us,
    aws_bedrockagent_knowledge_base.main,
    local_file.qna_intent_config
  ]

  triggers = {
    bot_id      = aws_lexv2models_bot.chatbot.id
    locale_id   = aws_lexv2models_bot_locale.en_us.locale_id
    kb_arn      = aws_bedrockagent_knowledge_base.main.arn
    model_id    = var.bedrock_model_id
    config_hash = sha256(local_file.qna_intent_config.content)
  }

  provisioner "local-exec" {
    command     = <<-EOT
      # Check if intent already exists
      $intentExists = aws lexv2-models list-intents `
        --bot-id ${aws_lexv2models_bot.chatbot.id} `
        --bot-version DRAFT `
        --locale-id ${aws_lexv2models_bot_locale.en_us.locale_id} `
        --region ${var.aws_region} `
        --query "intentSummaries[?intentName=='QnAIntent'].intentId" `
        --output text

      if ($intentExists) {
        Write-Host "QnAIntent already exists, skipping creation"
      } else {
        aws lexv2-models create-intent `
          --cli-input-json file://qna-intent.json `
          --region ${var.aws_region}
        Write-Host "QnAIntent created successfully with Bedrock KB configuration"
      }
    EOT
    interpreter = ["PowerShell", "-Command"]
  }
}

# Build the bot locale
resource "null_resource" "build_bot_locale" {
  depends_on = [
    aws_lexv2models_intent.welcome,
    null_resource.create_qna_intent
  ]

  triggers = {
    bot_id    = aws_lexv2models_bot.chatbot.id
    locale_id = aws_lexv2models_bot_locale.en_us.locale_id
    timestamp = timestamp()
  }

  provisioner "local-exec" {
    command     = <<-EOT
      aws lexv2-models build-bot-locale `
        --bot-id ${aws_lexv2models_bot.chatbot.id} `
        --bot-version DRAFT `
        --locale-id ${aws_lexv2models_bot_locale.en_us.locale_id} `
        --region ${var.aws_region}
      
      Write-Host "Waiting for bot build to complete..."
      Start-Sleep -Seconds 30
    EOT
    interpreter = ["PowerShell", "-Command"]
  }
}

# ============================================
# OUTPUTS
# ============================================

output "lex_bot_id" {
  value       = aws_lexv2models_bot.chatbot.id
  description = "Lex Bot ID"
}

output "lex_bot_name" {
  value       = aws_lexv2models_bot.chatbot.name
  description = "Lex Bot Name"
}
