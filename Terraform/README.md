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
