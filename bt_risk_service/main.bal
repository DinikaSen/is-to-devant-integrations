import ballerina/http;

listener http:Listener httpListener = check new http:Listener(9090);

service /risk/v1 on httpListener {

    // POST /risk/v1/evaluate
    resource function post evaluate(@http:Payload EvaluateRequest evalReq)
            returns EvaluateAllowResponse|EvaluateDenyResponse|http:InternalServerError {
        return evaluateRisk(evalReq);
    }
}
