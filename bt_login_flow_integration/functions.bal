import ballerina/http;

// Call the userstore service to look up a user by username
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

// Call the risk service to evaluate risk for a username and IP address
function evaluateRiskScore(string username, string ipAddress) returns RiskEvaluateResponse|error {
    RiskEvaluateRequest riskReq = {username: username, ipAddress: ipAddress};
    return check riskClient->post("/evaluate", riskReq);
}

// Build the final login decision response
function buildLoginDecision(string username, string ipAddress) returns LoginDecisionResponse|error {
    // Step 1: Lookup user in userstore
    UserstoreLookupFoundResponse|UserstoreLookupNotFoundResponse lookupResult = check lookupUserInStore(username);

    // Step 2: User not found — deny immediately
    if lookupResult is UserstoreLookupNotFoundResponse {
        return {
            decision: "DENY",
            reason: "USER_NOT_FOUND",
            userStore: {exists: false}
        };
    }

    // Step 3: User found — evaluate risk
    UserStoreInfo userStoreInfo = {
        exists: true,
        externalId: lookupResult.externalId
    };

    RiskEvaluateResponse riskResult = check evaluateRiskScore(username, ipAddress);
    RiskInfo riskInfo = {
        allow: riskResult.allow,
        score: riskResult.score
    };

    // Step 4: Risk blocked
    boolean isAllowed = riskResult.allow;
    if !isAllowed {
        return {
            decision: "DENY",
            reason: "RISK_BLOCKED",
            userStore: userStoreInfo,
            risk: riskInfo
        };
    }

    // Step 5: All checks passed — allow
    return {
        decision: "ALLOW",
        reason: "OK",
        userStore: userStoreInfo,
        risk: riskInfo
    };
}
