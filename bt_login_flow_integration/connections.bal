import ballerina/http;

// HTTP client for the Userstore service secured with OAuth2 client credentials
final http:Client userstoreClient = check new (userstoreServiceUrl, auth = {
    tokenUrl: userstoreTokenUrl,
    clientId: userstoreClientId,
    clientSecret: userstoreClientSecret
});

// HTTP client for the Risk service secured with OAuth2 client credentials
final http:Client riskClient = check new (riskServiceUrl, auth = {
    tokenUrl: riskTokenUrl,
    clientId: riskClientId,
    clientSecret: riskClientSecret
});
