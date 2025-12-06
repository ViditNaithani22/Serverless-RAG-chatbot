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

#### Security Layers
Within the Lambda function, deployed the following logic: 1) Limit the number of user requests per minute, 2) user input validation (i.e. checking if user message is empty or not exceeding certain length).  
Set route throttling with burst and rate limit in API Gateway. 


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
<br><br>
<img width="247" height="173" alt="image" src="https://github.com/user-attachments/assets/43615ef0-85df-4a79-95ed-f4586528661b" />
<br><br>
Next step is to create a knowledge-base with <b>Amazon Bedrock</b>. The knowledge-base stores the vectors and has the capability to return the vectors that matches the question.<br>
We go to Amazon Bedrock, click on "Knowledge Bases", click on "Create" to create a new "Knowledgebase with vector store" for "Unstructured data" 
<br>
<img width="946" height="390" alt="image" src="https://github.com/user-attachments/assets/4310770b-0c1a-4516-94df-d99dc1f8b4eb" />
<br><br>
Configure your S3 bucket with PDFs as your datasource
<br>
<img width="596" height="203" alt="bedrock7" src="https://github.com/user-attachments/assets/999daa93-8655-4728-9252-50896999b040" />
<br><br>
Select an embedding model like Titan Text Embeddings V2, and choose S3 Vectors to store the vectors generated by the embedding model.
<br>
<img width="371" height="292" alt="image" src="https://github.com/user-attachments/assets/d21ad40a-d83f-47ad-bffe-a2e61976413a" />
<br><br>
Go to your knowledgebase and select your data source, and then click on "Sync". Everytime you add a new PDF to your S3 bucket you click on sync, this recreates the vectors from the data source. 
<br>
<img width="849" height="334" alt="image" src="https://github.com/user-attachments/assets/f5666851-0b80-41ed-8788-4a06abedc44d" />
<br><br>
Next We will create LEX chatbot. Choose Traditional Blank Bot, give bot name, set IAM permissions and language of the bot.
<br>
<img width="418" height="271" alt="lex3" src="https://github.com/user-attachments/assets/1ed795ce-81a6-4a51-97bd-75a1526a4d5e" />
<img width="303" height="316" alt="lex4" src="https://github.com/user-attachments/assets/a498ed49-19ea-463f-ab16-adf934d5b678" />
<img width="308" height="132" alt="lex5" src="https://github.com/user-attachments/assets/585fad2a-4109-4f63-ae35-8c5cecd18af7" />
<img width="308" height="258" alt="lex6" src="https://github.com/user-attachments/assets/f836dc6c-e10b-4ccf-9a51-44809f679285" />
<br><br>
Now we create an intent(action) for the chatbot if user greets it with "Hi", "Hello", etc. Here we define what response chatbot must give to a specific user query.<br>
Give name to the intent, and in the "sample utterences" define all the ways user might greet the chatbot.
<img width="472" height="298" alt="lex7" src="https://github.com/user-attachments/assets/675a4f13-3722-485f-8b6a-b0785812436d" />
<img width="313" height="283" alt="lex8" src="https://github.com/user-attachments/assets/1827b190-2db6-4c9a-a8d5-0f8c85aa1b00" />
<br><br>
In the "initial response" define the message from the chatbot. Then click on "Advanced Options"
<br>
<img width="343" height="186" alt="lex9" src="https://github.com/user-attachments/assets/cf20c0e2-ca22-436e-9abc-5b1ec6a9a645" />
<br><br>
Expand "Set Values", under "Next Step in conversation" select "wait for users input", and comeback and save the intent.
<br>
<img width="341" height="397" alt="lex10" src="https://github.com/user-attachments/assets/bcd46bef-d827-46df-a7d3-0becaf855968" />
<br><br>
Next we will add another intent for the chatbot to answer user questions from the PDF files. If the user query does not match with any options mentioned in the "sample utterences" then the chatbot will use this intent to answer the question. For this intent we will give the chatbot access to our bedrock knowledge base to search the vectors of the training data that matches the user question. Then we will use Claude 3 Haiku to create a user friendly response for this intent.
<br>
Select "use built-in intent" option, then select Amazon.QnAIntent option, and give the intent a name.
<br>
<img width="149" height="70" alt="lex15" src="https://github.com/user-attachments/assets/f78a4715-50e3-4086-a61c-6e517047a982" />
<img width="304" height="187" alt="lex16" src="https://github.com/user-attachments/assets/275b7bf1-00ff-4f71-bec2-baf04b94314e" />
<br><br>
Select the model, select bedrock knowledgebase, and paste your knowledgebase ID 
<br>
<img width="304" height="298" alt="image" src="https://github.com/user-attachments/assets/7ced26c5-1cb8-48f5-ab90-f30aa0278336" />
<br><br>
Click on "Build", this add the intents to the chatbot, and then click on "Test" to check whether these intents work.
<br>
<img width="701" height="190" alt="lex21" src="https://github.com/user-attachments/assets/db0d3f8f-7d27-475e-ac2c-eb158296a79e" />
<img width="196" height="296" alt="lex22" src="https://github.com/user-attachments/assets/48e26962-80a2-4282-a1ed-ed0b228a6645" />
<br><br>
Now we will create the two DynamoDb tables. "ChatbotSessions" and "ChatbotRateLimits". "ChatbotSessions" is used to record user session ID and user ID. Each record will be automatically deleted after 24 hours by turning on TTL (time to live). "ChatbotRateLimits" is used to record the device IP and the number of requests the decive has sent in the last one minute. here each record will last only one hour using TTL. 

Let's create "ChatbotSessions". Name the partition key as userID, which will store the userID. The partition key makes each record unique and helps you get and update the record. 
<br>
<img width="603" height="317" alt="dynamodb3" src="https://github.com/user-attachments/assets/04bacaed-493e-4386-9cc9-b2605a566c29" />
<br><br>
Turn On the TTL option for this table
<img width="910" height="302" alt="dynamodb6" src="https://github.com/user-attachments/assets/b898008b-45bb-4d72-abe4-9a537ba679fb" />
<br><br>
Similarly we will create "ChatbotRateLimits" and name the partition key as identifier which will store user's device IP. Also turn on the TTL option for this table as well.
<br>
<img width="829" height="173" alt="image" src="https://github.com/user-attachments/assets/6ad5d2eb-42e8-4451-8a1e-b947ac2f609e" />
<br><br>
Now we will create the Lambda function which will carry the entire backend logic for our chatbot. The Lambda function code will be explained in detail in the "Backend" folder of this repository.<br>
Create a new Lambda fucntion in your console. Copy the code in the "Backend/lambda-function.mjs" file and paste it in your lambda function. Replace the values of BOT_ID, BOT_ALIAS_ID, SESSIONS_TABLE, and  RATE_LIMIT_TABLE with the values that you have.<br>
<img width="578" height="123" alt="image" src="https://github.com/user-attachments/assets/11fdcbef-16a9-4a18-94f5-529122362376" />
<br>
<img width="882" height="349" alt="image" src="https://github.com/user-attachments/assets/cb8b8292-71fb-4a29-bac3-f3056031889c" />
<br><br>
Now we will give our Lambda function the access to the DynamoDb tables and the LEX bot. For this go to "Configuration" and select "Permissions". Then click on the Lambda role under "Role name".<br> 
<img width="919" height="172" alt="dynamodb8" src="https://github.com/user-attachments/assets/240d94e5-f28d-447f-9725-544e5a81577a" />
<br><br>
Click on "Add permissions" then select "Create inline policy". Then select "JSON".  
<br>
<img width="788" height="272" alt="image" src="https://github.com/user-attachments/assets/8f12416f-2ad1-47cd-9341-6cb8d25c387e" />
<br>
<img width="797" height="206" alt="image" src="https://github.com/user-attachments/assets/55420e45-ad08-43e5-9cdd-6f8dda36790a" />
<br><br>
Copy the json code in the "Backend/lambda-permission-lex-dynamodb.json" file and paste it here. And then save the policy.
<br>
<img width="791" height="315" alt="image" src="https://github.com/user-attachments/assets/ee79f68a-b80c-46fc-b185-007149f76e3a" />
<br><br>
Back in our Lambda function under "Configuration", select "General configuration" and increase the "Timeout" to 25 secs.
<br>
<img width="481" height="148" alt="image" src="https://github.com/user-attachments/assets/d39b3768-479e-48b3-b22b-ca2dce49148b" />
<br><br>
Now lets test the lambda function out. Go to "Test", give it a name, copy the json code from "Backend/lambda-test-case-1.json" file and paste it here. Click on "save" and then click on "test". You should see the following output.<br>
<img width="813" height="293" alt="image" src="https://github.com/user-attachments/assets/30acecb3-1dd7-4da9-a7eb-a17652ce0f40" />
<br>
<img width="592" height="205" alt="image" src="https://github.com/user-attachments/assets/0fa0aedd-caac-4a0b-aab4-54d29d75419a" />
<br><br>
Similarly test the "Backend/lambda-test-case-2.json" as well.
<br>
<img width="767" height="205" alt="image" src="https://github.com/user-attachments/assets/cb079608-a9ab-4a4c-b6c4-edefd0adfab5" />
<br><br>

Finally its time to create the API gateway, which will give us the link through which users can send POST request to the lambda function carrying their message and user ID.<br>
For this project we will create HTTP API gateway.<br>
<img width="930" height="217" alt="api3" src="https://github.com/user-attachments/assets/603c7409-56f3-4376-bbee-5baeb3a12b58" />
<br><br>
Give it a name and keep everything at default setting.<br>
<img width="848" height="333" alt="api5" src="https://github.com/user-attachments/assets/628b23d6-947a-46dd-8c1e-6b3cedadfab9" />
<br><br>
Create a "/" POST route. Then click on "POST" of your created route, then click on "Attatch integration", then click "Create and attatch an integration".<br>
<img width="809" height="190" alt="api7" src="https://github.com/user-attachments/assets/d76deb13-89ac-4648-bfe3-a13177acdada" />
<br>
<img width="805" height="236" alt="api9" src="https://github.com/user-attachments/assets/e5157bda-2094-41c5-8754-63e562c6e136" />
<br>
<img width="812" height="244" alt="api10" src="https://github.com/user-attachments/assets/b4df3a0c-e930-40f6-aafa-4e7e3b5ff5be" />
<br><br>
For "Integration type" select "Lambda Function". Search and select your lambda function and keep the timeout at 30000 secs.<br>
<img width="673" height="191" alt="api11" src="https://github.com/user-attachments/assets/8ebc7a5f-6443-4f6e-ab4a-f193bb935a55" />
<br>
<img width="601" height="259" alt="image" src="https://github.com/user-attachments/assets/46550e63-c5e1-4478-a15e-d16aa1febd83" />
<br><br>
Now we go to "CORS" option and give the following CORS configuration.
<br>
<img width="793" height="342" alt="api15" src="https://github.com/user-attachments/assets/ae2845ef-40b0-42f9-a249-82dd0b33e370" />
<br><br>
Click on Deploy and create a new stage. Give it a name and enable automatic deployment <br>
<img width="310" height="196" alt="api18" src="https://github.com/user-attachments/assets/feea513a-48bd-4c04-8210-a7a848728cd2" />
<br>
<img width="638" height="319" alt="api19" src="https://github.com/user-attachments/assets/06486100-4984-4527-a51a-d2e80626bd63" />
<br><br>
Now got to "Stages" and select your newly created stage. Copy the link under "Invoke URL" and paste this link in your chat-bot-ui.html file. Under its <script> section paste it as the value for API_ENDPOINT variable. Do not forget to put '/' at the end of the url.<br>  
<img width="648" height="278" alt="api20" src="https://github.com/user-attachments/assets/0d8ddadb-20d2-459e-91fd-07a51a3d176c" />
<br>
<img width="701" height="378" alt="api21" src="https://github.com/user-attachments/assets/05aade7c-33a2-47f0-a9b3-385c74abd3a0" />
<br>
After updating the chat-bot-ui.html file, reupload it to the backend S3 bucket. And test your chatbot out using your frontend. 
















