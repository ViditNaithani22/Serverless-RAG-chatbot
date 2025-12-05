# Infrastructure Deployment (Terraform)

## Prerequisites
- AWS CLI configured
- Terraform installed
- IAM permissions to create Bedrock KB, S3, Lambda, DynamoDB, Lex, CloudFront, etc.

## Commands

#### 1. Initialize Terraform (first time or after adding new providers)
### terraform init

#### 2. Format your Terraform files (optional but recommended)
### terraform fmt

#### 3. Validate your configuration
### terraform validate

#### 4. Preview what will be created
### terraform plan

#### 5. Create all resources (there should be 40)
### terraform apply

#### 6. destroy everything
### terraform destroy

#### Important things to note:
1) Terraform does not currently provide the appropriate resource block to create a vector index for Amazon Bedrock knowledge base. So we are creating the vector index using AWS SDK javascript methods which you can find in scripts/createVectorIndex.js
2) Terraform does not currently provide the provision for Amazon Bedrock knowledge base to use S3 vector-store bucket to store vectors. Therefore here we are using Opensearch serverless service to store vectors (it is significantly more expensive than S3 vector store).
3) Terraform does not currently provide the appropriate resource block to create LEX chatbot locale. So we are using AWS CLI to create it.
4) Terraform does not currently provide the appropriate resource block to create QnA intent for LEX chatbot. So we are using AWS CLI to create it. 
