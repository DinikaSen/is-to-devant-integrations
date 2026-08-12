import ballerina/http;

// HTTP client for the Userstore service
final http:Client userstoreClient = check new (userstoreServiceUrl);
