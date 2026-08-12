import ballerina/http;
import ballerina/log;

listener http:Listener httpListener = check new http:Listener(8083);

service / on httpListener {

    // GET / — WebSub subscription/unsubscription verification
    // WSO2 IS sends hub.challenge as a query param; echo it back to confirm readiness
    resource function get .(@http:Query string hub\.challenge = "") returns string|http:BadRequest {
        if hub\.challenge == "" {
            log:printWarn("GET request received without hub.challenge — returning 400");
            return <http:BadRequest>{body: {message: "Missing hub.challenge query parameter"}};
        }
        log:printInfo("Subscription verification request received", hubChallenge = hub\.challenge);
        return hub\.challenge;
    }

    // POST / — Receive webhook event notifications from WSO2 IS
    resource function post .(@http:Payload json rawPayload, @http:Header string? x\-hub\-signature = ())
            returns http:Ok|http:Unauthorized|http:InternalServerError {
        return handleWebhookEvent(rawPayload, x\-hub\-signature);
    }
}
