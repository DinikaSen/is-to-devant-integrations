import ballerina/http;

listener http:Listener httpListener = check new http:Listener(8080);

service /userstore/v1 on httpListener {

    // POST /userstore/v1/users/lookup
    resource function post users/lookup(@http:Payload LookupRequest lookupReq)
            returns LookupFoundResponse|LookupNotFoundResponse|http:InternalServerError {
        string username = lookupReq.username;
        return lookupUser(username);
    }

    // POST /userstore/v1/users
    resource function post users(@http:Payload CreateUserRequest createReq)
            returns http:Created|http:InternalServerError {
        CreateUserResponse newUserResponse = createUser(createReq);
        http:Created createdResponse = {body: newUserResponse};
        return createdResponse;
    }

    // GET /userstore/v1/users
    resource function get users() returns UserRecord[] {
        return userStore;
    }
}
