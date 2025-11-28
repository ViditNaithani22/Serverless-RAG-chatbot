import { Client } from "@opensearch-project/opensearch";
import { AwsSigv4Signer } from "@opensearch-project/opensearch/aws";
import { defaultProvider } from "@aws-sdk/credential-provider-node";

// Environment variables
const OPENSEARCH_ENDPOINT = process.env.OPENSEARCH_ENDPOINT;
const INDEX_NAME = process.env.OPENSEARCH_INDEX_NAME;
const VECTOR_DIM = Number(process.env.VECTOR_DIM || 1024);
const REGION = process.env.AWS_REGION || "us-east-1";

if (!OPENSEARCH_ENDPOINT || !INDEX_NAME) {
  console.error("❌ Missing required environment variables");
  console.error("OPENSEARCH_ENDPOINT:", OPENSEARCH_ENDPOINT);
  console.error("INDEX_NAME:", INDEX_NAME);
  process.exit(1);
}

async function createIndex() {
  console.log(`\n🔧 Connecting to OpenSearch at: ${OPENSEARCH_ENDPOINT}`);
  console.log(`📝 Index name: ${INDEX_NAME}`);
  console.log(`📏 Vector dimensions: ${VECTOR_DIM}`);
  console.log(`🌍 Region: ${REGION}\n`);

  // Create OpenSearch client with AWS SigV4 signing
  const client = new Client({
    ...AwsSigv4Signer({
      region: REGION,
      service: "aoss",
      getCredentials: () => {
        const credentialsProvider = defaultProvider();
        return credentialsProvider();
      },
    }),
    node: `https://${OPENSEARCH_ENDPOINT}`,
  });

  console.log(`🔍 Checking if index "${INDEX_NAME}" exists...\n`);

  try {
    const exists = await client.indices.exists({ index: INDEX_NAME });

    if (exists.body === true) {
      console.log(`✓ Index "${INDEX_NAME}" already exists, skipping creation.`);
      return;
    }
  } catch (err) {
    if (err.meta?.statusCode === 404) {
      console.log(`Index does not exist, proceeding with creation...`);
    } else {
      console.error("Error checking index existence:", err.message);
      throw err;
    }
  }

  console.log(`⏳ Creating vector index "${INDEX_NAME}"...\n`);

  const indexBody = {
    settings: {
      index: {
        knn: true,
        "knn.algo_param.ef_search": 512,
      }
    },
    mappings: {
      properties: {
        "bedrock-knowledge-base-default-vector": {
          type: "knn_vector",
          dimension: VECTOR_DIM,
          method: {
            name: "hnsw",
            space_type: "cosinesimil",
            engine: "faiss",
            parameters: {
              ef_construction: 512,
              m: 16
            }
          }
        },
        "AMAZON_BEDROCK_TEXT_CHUNK": {
          type: "text",
          index: true
        },
        "AMAZON_BEDROCK_METADATA": {
          type: "text",
          index: false
        }
      }
    }
  };

  console.log("📋 Index configuration:", JSON.stringify(indexBody, null, 2));

  const response = await client.indices.create({
    index: INDEX_NAME,
    body: indexBody
  });

  console.log("\n🎉 Vector index created successfully!");
  console.log("Response status:", response.statusCode);
  console.log("Response body:", JSON.stringify(response.body, null, 2));
}

createIndex().catch(err => {
  console.error("\n❌ Error creating vector index:");
  console.error("Message:", err.message);
  if (err.meta) {
    console.error("Status Code:", err.meta.statusCode);
    console.error("Response Body:", JSON.stringify(err.meta.body, null, 2));
  }
  console.error("\nFull error:", err);
  process.exit(1);
});