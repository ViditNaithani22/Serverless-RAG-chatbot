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


### Architecture Summary:

### Front-end
We store our HTML file in an **S3** bucket. Create a **CloudFront** distribution that has access to the S3 bucket. CloudFront generates a link that users can send a GET request to and view our chatbot website.

### Back-end

#### S3
We store our training data in the form of PDFs in an S3 bucket.

#### Amazon Bedrock
We create a **Knowledgebase** with **Amazon Bedrock** whose data source will be the S3 bucket.  
The Knowledgebase uses **Titan Text Embeddings V2 model** to generate vectors from our training data PDFs.  
These vectors are then stored in an **S3 Vector bucket** (the newest and cheapest option to store vectors).

#### Amazon Lex
Then we create a new bot with **Amazon Lex**.  
We create two "intents":

1. The first intent answers basic greetings from the user like "Hi" or "Hello".  
2. The second intent answers questions from the training data.  
   For this intent, Amazon Lex sends the user query to the Bedrock Knowledge Base, which has the capability to find the vectors from the training data that match the vectors from the user query.  
   The Knowledge Base returns the vectors to Amazon Lex, and Lex uses the **Claude 3 model** to use those vectors and create an answer readable to the user.

#### DynamoDB
We create two tables:

1. The first is to store **user session** for each user (For Lex to remember a user's previous chat, it needs a unique user session ID with every user query).  
2. The second is to store the **number of requests sent by the user to the Lambda function in one minute**.  
   (This is to detect bots. If the number of requests sent by the user in one minute is more than **10**, then the Lambda will not send the user queries to Lex for the next 60 seconds.)

#### Amazon Lambda
All the questions sent by the user will be directed to this **Lambda function** to process.

The Lambda function does these three tasks for a new user:  
1) Creates a **new user session ID**. Stores user session ID and userID received from the user as a new record in the DynamoDB table.  
2) Creates a new record in the DynamoDB table where for the **device IP** it tracks the number of requests received in the past one minute.  
3) Sends the user query to the **Lex chatbot** with the user session ID and returns the Lex response back to the user.

#### API Gateway
The front-end webpage has a form using which the user will send a POST request to this **API Gateway**.  
The POST request body has a userID and a message (user query).  
The API Gateway will redirect the request to the Lambda function.


### Detailed instructions
We will upload the HTML file "chat-bot-ui.html" in an <b>S3</b> bucket without public access. (you can find this file in the "Frontend" directory of this repository) <br> 
<br>
<img width="238" height="160" alt="image" src="https://github.com/user-attachments/assets/78e8f460-8446-4932-a276-95ed7b7fa2f7" />
<br><br>
Then we will create a <b>CloudFront</b> distribution. Mention chat-bot-ui.html as the default root object. Mention the S3 bucket as the OAC, Origin Name, and Origin Domain, this should automatically create a bucket policy for our S3 bucket that grants the cloudfront the access to the bucket.<br><br>

<img width="255" height="116" alt="image" src="https://github.com/user-attachments/assets/04491784-cb0d-45dc-afb6-f5992fc13115" /><br>
<img width="613" height="321" alt="image" src="https://github.com/user-attachments/assets/ab116162-16f6-46d7-aaad-ef2ef05cd862" /><br>
<img width="354" height="310" alt="image" src="https://github.com/user-attachments/assets/df5c3c74-350e-43ba-8225-708f4808f76c" /><br>
<br>
you should be able to see your website on this URL provided by the Cloudfront. Don't forget to put "https://" before it <br>
<br>
<img width="155" height="97" alt="image" src="https://github.com/user-attachments/assets/9b6ec222-2df7-427b-876e-54b3b2cf6b3d" /><br>
<br><br>
The first step for the backend is to create an <b>S3</b> bucket and upload your PDF files in it. These files contain the data you want your chatbot to learn and become expert in answering any questions from these files. 
<br>
<img width="247" height="173" alt="image" src="https://github.com/user-attachments/assets/43615ef0-85df-4a79-95ed-f4586528661b" />
<br><br>
Next step is to create a knowledge-base with <b>Amazon Bedrock</b>. The knowledge-base stores the vectors and has the capability to return the vectors that matches the question.<br>
We go to Amazon Bedrock, click on "Knowledge Bases", click on "Create" to create a new "Knowledgebase with vector store" for "Unstructured data" 
<br><br>
<img width="946" height="386" alt="bedrock4" src="https://github.com/user-attachments/assets/eae7931f-627e-4183-a199-c9fc6defc80f" />
<br><br>



