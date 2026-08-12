import ballerina/http;

listener http:Listener httpListener = check new http:Listener(8082);

service / on httpListener {

    // POST / — WSO2 IS Flow Extension endpoint
    resource function post .(@http:Payload FlowExtensionRequest flowReq)
            returns SuccessResponse|FailedResponse|http:InternalServerError {
        SuccessResponse|FailedResponse|ErrorResponse result = handleFlowExtension(flowReq);
        if result is ErrorResponse {
            return {body: result};
        }
        return result;
    }
}
