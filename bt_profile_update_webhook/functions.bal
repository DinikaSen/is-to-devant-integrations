import ballerina/crypto;
import ballerina/http;
import ballerina/log;

const string USER_CREATED_EVENT_URI = "https://schemas.identity.wso2.org/events/user/event-type/userCreated";
const string USERNAME_CLAIM_URI = "http://wso2.org/claims/username";
const string EMAIL_CLAIM_URI = "http://wso2.org/claims/emailaddress";
const string FIRSTNAME_CLAIM_URI = "http://wso2.org/claims/givenname";
const string LASTNAME_CLAIM_URI = "http://wso2.org/claims/lastname";

// Verify the x-hub-signature HMAC-SHA256 header against the raw payload
function verifySignature(string rawBody, string signatureHeader) returns boolean|error {
    // Header format: "sha256=<hex>"
    if !signatureHeader.startsWith("sha256=") {
        return false;
    }
    string receivedHex = signatureHeader.substring(7);
    byte[] computedHmac = check crypto:hmacSha256(rawBody.toBytes(), webhookSecret.toBytes());
    string computedHex = computedHmac.reduce(function(string acc, byte b) returns string {
        string hexByte = b.toHexString();
        return acc + (hexByte.length() == 1 ? "0" + hexByte : hexByte);
    }, "");
    return computedHex == receivedHex;
}

// Extract a specific claim value from the user's claims array
function extractClaimValue(WebhookClaim[] claims, string claimUri) returns string? {
    foreach WebhookClaim claim in claims {
        string uri = claim.uri;
        if uri == claimUri {
            return claim.value;
        }
    }
    return ();
}

// Process the userCreated event: extract user info and register in the userstore
function processUserCreatedEvent(UserCreatedEventData eventData) returns error? {
    WebhookUser webhookUser = eventData.user;
    string userId = webhookUser.id;
    WebhookClaim[] claims = webhookUser.claims ?: [];

    string? username = extractClaimValue(claims, USERNAME_CLAIM_URI);
    string? email = extractClaimValue(claims, EMAIL_CLAIM_URI);
    string? firstName = extractClaimValue(claims, FIRSTNAME_CLAIM_URI);
    string? lastName = extractClaimValue(claims, LASTNAME_CLAIM_URI);

    log:printInfo("Extracted user details from webhook event",
        userId = userId,
        username = username ?: "(missing)",
        email = email ?: "(missing)",
        firstName = firstName ?: "(missing)",
        lastName = lastName ?: "(missing)"
    );

    if username is () || email is () {
        return error("Missing required claims: username or email not found in webhook event");
    }

    CreateUserRequest createReq = {
        username: username,
        email: email,
        wso2UserId: userId,
        firstName: firstName ?: "",
        lastName: lastName ?: "",
        'source: "WSO2_IS_SELF_REGISTRATION"
    };

    log:printInfo("Calling userstore to create user",
        userstoreUrl = userstoreServiceUrl,
        username = createReq.username,
        email = createReq.email,
        wso2UserId = createReq.wso2UserId
    );

    http:Response response = check userstoreClient->post("/users", createReq);
    int statusCode = response.statusCode;
    json responseBody = check response.getJsonPayload();

    if statusCode == 201 {
        CreateUserResponse createResp = check responseBody.cloneWithType(CreateUserResponse);
        log:printInfo("User successfully created in userstore",
            externalId = createResp.externalId,
            username = createResp.username,
            status = createResp.status
        );
    } else {
        log:printWarn("Userstore returned unexpected status",
            statusCode = statusCode,
            responseBody = responseBody.toString()
        );
    }
}

// Handle the incoming webhook POST event
function handleWebhookEvent(json rawPayload, string? signatureHeader) returns http:Ok|http:Unauthorized|http:InternalServerError {
    string rawBody = rawPayload.toString();

    log:printInfo("Received webhook event", rawPayload = rawBody);

    // Signature verification
    if !skipSignatureVerification {
        if signatureHeader is () {
            log:printWarn("Missing x-hub-signature header — rejecting request");
            return <http:Unauthorized>{body: {message: "Missing x-hub-signature header"}};
        }
        boolean|error isValid = verifySignature(rawBody, signatureHeader);
        if isValid is error || !isValid {
            log:printWarn("HMAC signature verification failed — rejecting request",
                signature = signatureHeader
            );
            return <http:Unauthorized>{body: {message: "Invalid signature"}};
        }
        log:printInfo("HMAC signature verified successfully");
    } else {
        log:printInfo("Signature verification skipped (skipSignatureVerification=true)");
    }

    // Parse the event envelope
    WebhookEvent|error webhookEvent = rawPayload.cloneWithType(WebhookEvent);
    if webhookEvent is error {
        log:printError("Failed to parse webhook event payload", 'error = webhookEvent);
        return <http:InternalServerError>{body: {message: "Failed to parse event payload"}};
    }

    log:printInfo("Parsed webhook event",
        iss = webhookEvent.iss,
        jti = webhookEvent.jti,
        rci = webhookEvent.rci ?: "(none)"
    );

    // Check for the userCreated event URI
    map<json> events = webhookEvent.events;
    json? userCreatedJson = events[USER_CREATED_EVENT_URI];
    if userCreatedJson is () {
        log:printInfo("No userCreated event found in payload — ignoring", eventKeys = events.keys().toString());
        return <http:Ok>{body: {message: "Event ignored — not a userCreated event"}};
    }

    log:printInfo("userCreated event detected — processing");

    UserCreatedEventData|error eventData = userCreatedJson.cloneWithType(UserCreatedEventData);
    if eventData is error {
        log:printError("Failed to parse userCreated event data", 'error = eventData);
        return <http:InternalServerError>{body: {message: "Failed to parse userCreated event data"}};
    }

    error? processResult = processUserCreatedEvent(eventData);
    if processResult is error {
        log:printError("Error processing userCreated event", 'error = processResult, errorMessage = processResult.message());
        return <http:InternalServerError>{body: {message: processResult.message()}};
    }

    log:printInfo("Webhook event processed successfully");
    return <http:Ok>{body: {message: "User created successfully"}};
}
