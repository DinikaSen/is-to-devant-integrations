// Request/Response types

type LookupRequest record {|
    string username;
|};

type LookupFoundResponse record {|
    boolean exists;
    string externalId;
    string username;
    string status;
    string createdAt;
|};

type LookupNotFoundResponse record {|
    boolean exists;
    string username;
|};

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

// Internal user record stored in the JSON database
type UserRecord record {|
    string externalId;
    string username;
    string email;
    string wso2UserId;
    string firstName;
    string lastName;
    string 'source;
    string status;
    string createdAt;
|};
