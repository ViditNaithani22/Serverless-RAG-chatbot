# Serverless-RAG-chatbot
## Building a RAG chatbot with a serverless architecture using AWS along with an interactive frontend

### Youtube tutorial: (coming soon)
### Live project link: https://d330r4ax04vbs6.cloudfront.net/

#### Q1 Have you ever built a RAG chatbot?
#### Q2 Have you ever built a fully serverless application?
#### If your answer for the above two questions is no, then this project is for you. 

If you are a backend engineer, these questions are important for you because: 💁
1) ➡️ It has now become an industry standard for organizations to have a chatbot on their website that can answer questions about their policies and services.
2) ➡️ Companies expect you to understand serverless architecture, as it makes applications faster, cheaper, and easier to manage — you don’t manage the servers yourself and only pay for what you use.

I created a serverless AI chatbot that answers questions about Lord of the Rings using AWS! 
Ask it anything about Middle-earth! 🧙‍♂️ <br>
But go easy on it as it is trained on just two pdf files, one containing the summary and another containing the characters. 

Begin chat with one of these: hi, Hi, hey, Hey, hello, Hello <br> 
Ask questions like: <br>
What is "abc"? or What was "abc"? <br>
Where is "xyz" or Where was "xyz"? <br>
Or simply mention the name of a place or a character and it should give you a reply. <br>

![1761791315826](https://github.com/user-attachments/assets/bf0a2605-de38-4c3c-b3e6-9092596e9b4f)

AWS services used:<br>
🔹 Amazon Bedrock (Claude 3) - AI/ML foundation model <br>
🔹 AWS Lambda - Serverless compute <br>
🔹 API Gateway - REST API management <br>
🔹 DynamoDB - Rate limiting & session management <br> 
🔹 S3 + CloudFront - Global content deliver <br>
🔹 Amazon Lex - for text conversational interfaces <br>

Key Features: <br> 
✅ Fully serverless architecture (auto-scales, pay-per-use) <br> 
✅ Multi-layer security (rate limiting, throttling, input validation) <br>



### Let's understand the Architecture:
<img width="5963" height="2813" alt="Blank diagram (1)" src="https://github.com/user-attachments/assets/a976bb08-9dca-4271-8026-a2d4aa23b8d6" />
<br>
<br>
As you can see in the diagram, our architecture is divided into two parts, frontend and backend.<br>
The front-end is pretty simple. We will store a single html file "chat-bot-ui.html" in an <b>S3</b> bucket without public access.<br> 
Then we will create a <b>Cloud-Front</b> distribution. Mention chat-bot-ui.html as the default root object. Mention the S3 bucket as the OAC, Origin Name, and Origin Domain, this should automatically create a bucket policy for our S3 bucket that grants the cloudfront the access to the bucket.<br><br>

<img width="255" height="116" alt="image" src="https://github.com/user-attachments/assets/04491784-cb0d-45dc-afb6-f5992fc13115" /><br>
<img width="613" height="321" alt="image" src="https://github.com/user-attachments/assets/ab116162-16f6-46d7-aaad-ef2ef05cd862" /><br>
<img width="354" height="310" alt="image" src="https://github.com/user-attachments/assets/df5c3c74-350e-43ba-8225-708f4808f76c" /><br>
<br>
you should be able to see your website on this URL provided by the Cloudfront. Don't forget to put "https://" before it <br>
<br>
<img width="155" height="97" alt="image" src="https://github.com/user-attachments/assets/9b6ec222-2df7-427b-876e-54b3b2cf6b3d" /><br>





