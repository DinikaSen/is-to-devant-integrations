// --- Inbound webhook event types (WSO2 IS → this service) ---

type WebhookEvent record {|
    string iss;
    string jti;
    int iat;
    string rci?;
    map<json> events;
|};

// User created event data (under the userCreated event URI key)
type UserCreatedEventData record {|
    string initiatorType?;
    string initiatorIpAddress?;
    string action?;
    WebhookUser user;
    WebhookTenant tenant?;
    WebhookOrganization organization?;
    WebhookUserStore userStore?;
|};

type WebhookUser record {|
    string id;
    WebhookClaim[] claims?;
    WebhookOrganization organization?;
    string ref?;
|};

type WebhookClaim record {|
    string uri;
    string value;
|};

type WebhookTenant record {|
    string id?;
    string name?;
|};

type WebhookOrganization record {|
    string id?;
    string name?;
    string orgHandle?;
    int depth?;
|};

type WebhookUserStore record {|
    string id?;
    string name?;
|};

// --- Userstore create user API types ---

type CreateUserRequest record {|
    string username;
    string email;
    string wso2UserId;
    string firstName;
    string lastName;
    string 'source;
|};

type CreateUserResponse record {|
    string externalId;
    string username;
    string status;
|};
