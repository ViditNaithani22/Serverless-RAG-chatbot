// index.mjs
import { LexRuntimeV2Client, RecognizeTextCommand } from '@aws-sdk/client-lex-runtime-v2';
import { DynamoDBClient }  from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, GetCommand, PutCommand }  from '@aws-sdk/lib-dynamodb';


const lexClient = new LexRuntimeV2Client({ region: 'us-east-1' });
const dynamoClient = new DynamoDBClient({ region: 'us-east-1' });
const docClient = DynamoDBDocumentClient.from(dynamoClient);

// Configuration
const BOT_ID = '<LEX-bot-ID>';
const BOT_ALIAS_ID = '<LEX-bot-alias-ID>';
const LOCALE_ID = 'en_US';

const SESSIONS_TABLE = '<name of dynamodb table for storing user sessions>';
const RATE_LIMIT_TABLE = '<name of dynamodb table for storing no. of requests per user per minute>';
const MAX_REQUESTS_PER_MINUTE = 10; // Adjust as needed

// Rate limiting function
async function checkRateLimit(identifier) {
  const now = Date.now();
  const windowStart = now - 60000; // 1 minute window
  
  try {
      // Get existing rate limit record
      const result = await docClient.send(new GetCommand({
          TableName: RATE_LIMIT_TABLE,
          Key: { identifier: identifier }
      }));
      
      if (result.Item) {
          // Filter requests within time window
          const recentRequests = result.Item.requests.filter(time => time > windowStart);
          
          // Check if limit exceeded
          if (recentRequests.length >= MAX_REQUESTS_PER_MINUTE) {
              console.log(`Rate limit exceeded for ${identifier}: ${recentRequests.length} requests`);
              return { 
                  allowed: false, 
                  remaining: 0,
                  resetTime: Math.min(...recentRequests) + 60000
              };
          }
          
          // Add current request
          recentRequests.push(now);
          
          // Update DynamoDB
          await docClient.send(new PutCommand({
              TableName: RATE_LIMIT_TABLE,
              Item: {
                  identifier: identifier,
                  requests: recentRequests,
                  ttl: Math.floor((now + 3600000) / 1000) // Expire after 1 hour
              }
          }));
          
          return { 
              allowed: true, 
              remaining: MAX_REQUESTS_PER_MINUTE - recentRequests.length,
              resetTime: windowStart + 60000
          };
      } else {
          // First request from this identifier
          await docClient.send(new PutCommand({
              TableName: RATE_LIMIT_TABLE,
              Item: {
                  identifier: identifier,
                  requests: [now],
                  ttl: Math.floor((now + 3600000) / 1000)
              }
          }));
          
          return { 
              allowed: true, 
              remaining: MAX_REQUESTS_PER_MINUTE - 1,
              resetTime: now + 60000
          };
      }
  } catch (error) {
      console.error('Rate limit check error:', error);
      // On error, allow request (fail open)
      return { allowed: true, remaining: MAX_REQUESTS_PER_MINUTE };
  }
}


export const handler = async (event) => {
  try {
    console.log('Event:', JSON.stringify(event));

    // Get IP address from HTTP API event
    const ipAddress = event.requestContext?.http?.sourceIp || 'unknown';
    console.log('Request from IP:', ipAddress);

    // Check rate limit
    const rateLimitResult = await checkRateLimit(ipAddress);
    
    if (!rateLimitResult.allowed) {
        return {
            statusCode: 429,
            headers: {
                'Access-Control-Allow-Origin': '*',
                'Content-Type': 'application/json',
                'X-RateLimit-Limit': MAX_REQUESTS_PER_MINUTE.toString(),
                'X-RateLimit-Remaining': '0',
                'X-RateLimit-Reset': new Date(rateLimitResult.resetTime).toISOString()
            },
            body: JSON.stringify({ 
                error: 'Too many requests. Please try again later.',
                retryAfter: Math.ceil((rateLimitResult.resetTime - Date.now()) / 1000)
            })
        };
    }    

    const body = JSON.parse(event.body || '{}');
    const userMessage = body.message;
    const userId = body.userId || 'anonymous-user';

    if (!userMessage || userMessage.trim() === '') {
      return {
        statusCode: 400,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ error: 'Message cannot be empty' })
      };
    }


    // Validate message length
    if (userMessage.length > 500) {
      return {
          statusCode: 400,
          headers: {
              'Access-Control-Allow-Origin': '*',
              'Content-Type': 'application/json'
          },
          body: JSON.stringify({ error: 'Message too long (max 500 characters)' })
      };
    }

    let sessionId;

    try {
      const getCommand = new GetCommand({
          TableName: SESSIONS_TABLE,
          Key: { userId: userId }
      });
      const result = await docClient.send(getCommand);
      
      if (result.Item) {
          sessionId = result.Item.sessionId;
          console.log('Found existing session:', sessionId);
      }
    } catch (err) {
      console.log('No existing session found');
    }

    if (!sessionId) {
      sessionId = `${userId}-${Date.now()}`;
      const putCommand = new PutCommand({
        TableName: SESSIONS_TABLE,
        Item: {
            userId: userId,
            sessionId: sessionId,
            createdAt: new Date().toISOString(),
            ttl: Math.floor(Date.now() / 1000) + 86400 // Expire after 24 hours
        }
      });
      await docClient.send(putCommand);
      console.log('Created new session:', sessionId);
    }

    const command = new RecognizeTextCommand({
      botId: BOT_ID,
      botAliasId: BOT_ALIAS_ID,
      localeId: LOCALE_ID,
      sessionId,
      text: userMessage
    });

    const response = await lexClient.send(command);

    let botMessage = 'Sorry, I could not understand that. Please try again.';
    if (response.messages && response.messages.length > 0) {
      botMessage = response.messages[0].content;
    }

    return {
      statusCode: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Allow-Methods': 'POST,OPTIONS',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        message: botMessage,
        sessionId
      })
    };

  } catch (error) {
    console.error('Error:', error);
    return {
      statusCode: 500,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        error: 'Failed to process message',
        details: error.message
      })
    };
  }
};
