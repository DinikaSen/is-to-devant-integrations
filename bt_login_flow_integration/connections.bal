import ballerina/http;

// HTTP client for the Userstore service (no auth required)
final http:Client userstoreClient = check new (userstoreServiceUrl);

// HTTP client for the Risk service (no auth required)
final http:Client riskClient = check new (riskServiceUrl);
