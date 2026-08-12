import ballerina/http;

listener http:Listener httpListener = check new http:Listener(8082);

service / on httpListener {

    // POST / — WSO2 IS Flow Extension endpoint
    // SUCCESS and FAILED both return 200 OK (actionStatus in body distinguishes them)
    // ERROR returns 500 so WSO2 IS aborts the flow
    resource function post .(@http:Payload FlowExtensionRequest flowReq)
            returns http:Ok|http:InternalServerError {
        SuccessResponse|FailedResponse|ErrorResponse result = handleFlowExtension(flowReq);
        if result is ErrorResponse {
            return <http:InternalServerError>{body: result};
        }
        return <http:Ok>{body: result};
    }
}
