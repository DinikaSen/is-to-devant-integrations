import ballerina/http;

// Extract the username from the http://wso2.org/claims/username claim in the flow event
function extractUsername(FlowExtensionRequest flowReq) returns string? {
    Event flowEvent = flowReq.event;
    Flow? flow = flowEvent.flow;
    if flow is () {
        return ();
    }
    FlowUser? flowUser = flow.user;
    if flowUser is () {
        return ();
    }
    UserClaim[]? claims = flowUser.claims;
    if claims is () {
        return ();
    }
    foreach UserClaim claim in claims {
        string claimUri = claim.uri;
        if claimUri == "http://wso2.org/claims/username" {
            string|string[] claimValue = claim.value;
            if claimValue is string {
                return claimValue;
            }
        }
    }
    return ();
}

// Call the userstore lookup endpoint and return the found/not-found response
function lookupUserInStore(string username) returns UserstoreLookupFoundResponse|UserstoreLookupNotFoundResponse|error {
    UserstoreLookupRequest lookupReq = {username: username};
    http:Response response = check userstoreClient->post("/users/lookup", lookupReq);
    json responseJson = check response.getJsonPayload();
    boolean exists = check responseJson.exists;
    if exists {
        return check responseJson.cloneWithType(UserstoreLookupFoundResponse);
    }
    return check responseJson.cloneWithType(UserstoreLookupNotFoundResponse);
}

// Build the flow extension response based on the userstore lookup result
function handleFlowExtension(FlowExtensionRequest flowReq) returns SuccessResponse|FailedResponse|ErrorResponse {
    // Extract username from claims
    string? username = extractUsername(flowReq);
    if username is () {
        return {
            actionStatus: "ERROR",
            errorMessage: "Missing username claim",
            errorDescription: "The http://wso2.org/claims/username claim was not found in the request."
        };
    }

    // Call userstore lookup
    UserstoreLookupFoundResponse|UserstoreLookupNotFoundResponse|error lookupResult = lookupUserInStore(username);
    if lookupResult is error {
        return {
            actionStatus: "ERROR",
            errorMessage: "External service failure",
            errorDescription: "The external service met with an unexpected error."
        };
    }

    // User not found — deny registration
    if lookupResult is UserstoreLookupNotFoundResponse {
        return {
            actionStatus: "FAILED",
            failureReason: "User not allowed",
            failureDescription: "You are currently restricted from creating new accounts."
        };
    }

    // User found — return externalId as a claim operation
    string externalId = lookupResult.externalId;
    return {
        actionStatus: "SUCCESS",
        operations: [
            {
                op: "replace",
                path: "/user/claims[uri=http://wso2.org/claims/external_id]",
                value: externalId
            }
        ]
    };
}
