# Serverless-RAG-chatbot
## Building a RAG chatbot with a serverless architecture using AWS along with an interactive frontend

### Youtube tutorial:
### Live project link: https://d330r4ax04vbs6.cloudfront.net/

### Have you ever built a RAG chatbot?
### Have you ever built a fully serverless application?
### If your answer for the above two questions is no, then this project is for you. 

If you are a backend engineer, these questions are important for you because: 💁
1) ➡️ It has now become an industry standard for organizations to have a chatbot on their website that can answer questions about their policies and services.
2) ➡️ Companies expect you to understand serverless architecture, as it makes applications faster, cheaper, and easier to manage — you don’t manage the servers yourself and only pay for what you use.

I created a serverless AI chatbot that answers questions about Lord of the Rings using AWS! 
Ask it anything about Middle-earth! 🧙‍♂️ But go easy on it as it is trained on just two pdf files, one containing the summary and another containing the characters. 

Begin chat with one of these: hi, Hi, hey, Hey, hello, Hello 
Ask questions like: 
What is "abc"? or What was "abc"?
Where is "xyz" or Where was "xyz"?
Or simply mention the name of a place or a character and it should give you a reply. 

### Here is the Architecture diagram:
<img width="5963" height="2813" alt="Blank diagram (1)" src="https://github.com/user-attachments/assets/a976bb08-9dca-4271-8026-a2d4aa23b8d6" />

AWS services used:
🔹 Amazon Bedrock (Claude 3) - AI/ML foundation model 
🔹 AWS Lambda - Serverless compute 
🔹 API Gateway - REST API management 
🔹 DynamoDB - Rate limiting & session management 
🔹 S3 + CloudFront - Global content deliver
🔹 Amazon Lex - for text conversational interfaces

Key Features: 
✅ Fully serverless architecture (auto-scales, pay-per-use) 
✅ Multi-layer security (rate limiting, throttling, input validation) 


