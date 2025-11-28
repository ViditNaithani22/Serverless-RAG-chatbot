# Get current AWS account info
data "aws_caller_identity" "current" {}

# ============================================
# OPENSEARCH SERVERLESS - VECTOR STORE
# ============================================

# Encryption Policy
resource "aws_opensearchserverless_security_policy" "encryption" {
  name        = "${var.project_name}-encryption-policy"
  type        = "encryption"
  description = "Encryption policy for Bedrock KB"

  policy = jsonencode({
    Rules = [
      {
        Resource     = ["collection/${var.project_name}-vectors"]
        ResourceType = "collection"
      }
    ]
    AWSOwnedKey = true # ✅ ADDED
  })
}

# Network Policy
resource "aws_opensearchserverless_security_policy" "network" {
  name = "${var.project_name}-network-policy"
  type = "network"

  policy = jsonencode([
    {
      Description = "Allow access from public and Bedrock"
      Rules = [
        {
          ResourceType = "collection"
          Resource     = ["collection/${var.project_name}-vectors"]
        }
      ]
      AllowFromPublic = true
    }
  ])
}

# OpenSearch Serverless Collection
resource "aws_opensearchserverless_collection" "vectors" {
  name = "${var.project_name}-vectors"
  type = "VECTORSEARCH"

  depends_on = [
    aws_opensearchserverless_security_policy.encryption,
    aws_opensearchserverless_security_policy.network
  ]

  tags = {
    Name = "${var.project_name}-vectors"

    Project = var.project_name
  }
}


locals {
  vector_index_name = "${var.project_name}-kb-index-${random_string.suffix.result}"
}


# run the script to create vector index
resource "null_resource" "create_vector_index" {
  depends_on = [
    aws_opensearchserverless_collection.vectors,
    aws_opensearchserverless_access_policy.data_access
  ]

  triggers = {
    collection_endpoint = aws_opensearchserverless_collection.vectors.collection_endpoint
    index_name          = local.vector_index_name
  }

  provisioner "local-exec" {
    command = "node ./scripts/createVectorIndex.js"

    environment = {
      OPENSEARCH_ENDPOINT   = replace(aws_opensearchserverless_collection.vectors.collection_endpoint, "https://", "")
      OPENSEARCH_INDEX_NAME = local.vector_index_name
      VECTOR_DIM            = 1024
      AWS_REGION            = var.aws_region
    }
  }
}

# Data Access Policy - ✅ CORRECTED FORMAT
resource "aws_opensearchserverless_access_policy" "data_access" {
  name = "${var.project_name}-data-access"
  type = "data"

  policy = jsonencode([
    {
      Rules = [
        {
          Resource = ["collection/${aws_opensearchserverless_collection.vectors.name}"]
          Permission = [
            "aoss:CreateCollectionItems",
            "aoss:DeleteCollectionItems",
            "aoss:UpdateCollectionItems",
            "aoss:DescribeCollectionItems"
          ]
          ResourceType = "collection"
        },
        {
          Resource = ["index/${aws_opensearchserverless_collection.vectors.name}/*"]
          Permission = [
            "aoss:CreateIndex",
            "aoss:DeleteIndex",
            "aoss:UpdateIndex",
            "aoss:DescribeIndex",
            "aoss:ReadDocument",
            "aoss:WriteDocument"
          ]
          ResourceType = "index"
        }
      ]
      Principal = [
        aws_iam_role.bedrock_kb_role.arn,
        data.aws_caller_identity.current.arn
      ]
    }
  ])

  depends_on = [
    aws_opensearchserverless_collection.vectors
  ]
}

# ============================================
# IAM ROLE FOR BEDROCK KNOWLEDGE BASE
# ============================================

resource "aws_iam_role" "bedrock_kb_role" {
  name = "${var.project_name}-kb-role"

  # ✅ IMPROVED with conditions
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:bedrock:${var.aws_region}:${data.aws_caller_identity.current.account_id}:knowledge-base/*"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-kb-role"

  }
}

# IAM Policy - S3 Access
resource "aws_iam_role_policy" "bedrock_kb_s3" {
  name = "${var.project_name}-kb-s3-policy"
  role = aws_iam_role.bedrock_kb_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.backend.arn,
          "${aws_s3_bucket.backend.arn}/*"
        ]
        Condition = {
          StringEquals = {
            "aws:PrincipalAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# IAM Policy - OpenSearch Access
resource "aws_iam_role_policy" "bedrock_kb_opensearch" {
  name = "${var.project_name}-kb-opensearch-policy"
  role = aws_iam_role.bedrock_kb_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "aoss:APIAccessAll"
        ]
        Resource = aws_opensearchserverless_collection.vectors.arn
      }
    ]
  })
}

# IAM Policy - Bedrock Model Access - ✅ SPECIFIC PERMISSIONS
resource "aws_iam_role_policy" "bedrock_kb_model" {
  name = "${var.project_name}-kb-model-policy"
  role = aws_iam_role.bedrock_kb_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel"
        ]
        Resource = [
          "arn:aws:bedrock:${var.aws_region}::foundation-model/${var.embedding_model_id}",
          "arn:aws:bedrock:${var.aws_region}::foundation-model/${var.bedrock_model_id}"
        ]
      }
    ]
  })
}


resource "time_sleep" "wait_for_index" {
  depends_on      = [null_resource.create_vector_index]
  create_duration = "5m"
}

# ============================================
# BEDROCK KNOWLEDGE BASE
# ============================================

resource "aws_bedrockagent_knowledge_base" "main" {
  name     = "${var.project_name}-knowledge-base"
  role_arn = aws_iam_role.bedrock_kb_role.arn

  description = "Knowledge base for ${var.project_name}"

  knowledge_base_configuration {
    type = "VECTOR"

    vector_knowledge_base_configuration {
      embedding_model_arn = "arn:aws:bedrock:${var.aws_region}::foundation-model/${var.embedding_model_id}"
    }
  }

  storage_configuration {
    type = "OPENSEARCH_SERVERLESS"

    opensearch_serverless_configuration {
      collection_arn    = aws_opensearchserverless_collection.vectors.arn
      vector_index_name = local.vector_index_name

      field_mapping {
        vector_field   = "bedrock-knowledge-base-default-vector"
        text_field     = "AMAZON_BEDROCK_TEXT_CHUNK"
        metadata_field = "AMAZON_BEDROCK_METADATA"
      }
    }
  }

  depends_on = [
    aws_opensearchserverless_collection.vectors,
    aws_opensearchserverless_access_policy.data_access,
    aws_iam_role_policy.bedrock_kb_s3,
    aws_iam_role_policy.bedrock_kb_opensearch,
    aws_iam_role_policy.bedrock_kb_model,
    null_resource.create_vector_index,
    time_sleep.wait_for_index
  ]

  tags = {
    Name = "${var.project_name}-kb"
  }
}

# ============================================
# BEDROCK DATA SOURCE
# ============================================

resource "aws_bedrockagent_data_source" "kb_source" {
  knowledge_base_id = aws_bedrockagent_knowledge_base.main.id
  name              = "${var.project_name}-backend-source"

  description = "S3 data source for ${var.project_name}"

  data_source_configuration {
    type = "S3"

    s3_configuration {
      bucket_arn = aws_s3_bucket.backend.arn

      # Optional: Specify inclusion/exclusion patterns
      # inclusion_prefixes = ["documents/"]
    }
  }

  # ✅ ADDED - Chunking configuration
  vector_ingestion_configuration {
    chunking_configuration {
      chunking_strategy = "FIXED_SIZE"

      fixed_size_chunking_configuration {
        max_tokens         = 300
        overlap_percentage = 20
      }
    }
  }

  # Optional: Configure sync schedule
  data_deletion_policy = "DELETE"

  depends_on = [
    aws_bedrockagent_knowledge_base.main
  ]
}

