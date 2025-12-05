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

#### After creating all resources, copy the "api_gateway_url" from the output, and paste it in the Frontend/chat-bot-ui.html file. 
<img width="476" height="126" alt="image" src="https://github.com/user-attachments/assets/2c87bd04-c327-4be3-9782-ca13ec8aed53" />
<img width="782" height="430" alt="image" src="https://github.com/user-attachments/assets/22a6e379-c733-4019-a1a0-7c5a289b82c1" />

#### Then upload the chat-bot-ui.html in the "lotr-chatbot-frontend-xyz" bucket.
<img width="418" height="213" alt="image" src="https://github.com/user-attachments/assets/6b18588f-0ea2-46ab-8b87-6bb01c85f124" />

#### Finally upload your PDF files in the "lotr-chatbot-backend-xyz" bucket.
<img width="367" height="200" alt="image" src="https://github.com/user-attachments/assets/39969f36-26c1-4e04-a9da-481c1ceef84c" />

#### 6. destroy everything
### terraform destroy

#### Important things to note:
1) Terraform does not currently provide the appropriate resource block to create a vector index for Amazon Bedrock knowledge base. So we are creating the vector index using AWS SDK javascript methods which you can find in scripts/createVectorIndex.js
2) Terraform does not currently provide the provision for Amazon Bedrock knowledge base to use S3 vector-store bucket to store vectors. Therefore here we are using Opensearch serverless service to store vectors (it is significantly more expensive than S3 vector store).
3) Terraform does not currently provide the appropriate resource block to create LEX chatbot locale. So we are using AWS CLI to create it.
4) Terraform does not currently provide the appropriate resource block to create QnA intent for LEX chatbot. So we are using AWS CLI to create it. 
