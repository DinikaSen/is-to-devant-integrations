import ballerina/http;

listener http:Listener httpListener = check new http:Listener(8081);

service /v1 on httpListener {

    // POST /v1/login/decision
    resource function post login/decision(@http:Payload LoginDecisionRequest loginReq)
            returns LoginDecisionResponse|http:InternalServerError {
        string username = loginReq.username;
        string ipAddress = loginReq.ipAddress;
        LoginDecisionResponse|error decisionResult = buildLoginDecision(username, ipAddress);
        if decisionResult is error {
            return {body: {code: 500, message: decisionResult.message()}};
        }
        return decisionResult;
    }
}
