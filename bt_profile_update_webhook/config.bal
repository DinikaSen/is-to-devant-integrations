// HMAC secret configured in WSO2 IS for this webhook
configurable string webhookSecret = ?;

// Set to true to skip HMAC verification (useful for local testing)
configurable boolean skipSignatureVerification = false;

// Userstore service base URL
configurable string userstoreServiceUrl = "https://b48cc93e-fa33-4420-a155-bc653b4d46be-prod.e1-us-east-azure.choreoapis.dev/dinika2/bt-userstore-service/v1.0";
