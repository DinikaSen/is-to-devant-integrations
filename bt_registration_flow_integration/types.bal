// --- Inbound request types (WSO2 IS → this service) ---

type FlowExtensionRequest record {|
    string actionType;
    Event event;
    AllowedOperation[] allowedOperations;
    string requestId;
|};

type Event record {|
    Flow flow?;
    Application application?;
    Tenant tenant?;
    Organization organization?;
|};

type Flow record {|
    string flowType?;
    string flowId?;
    string portalUrl?;
    FlowUser user?;
|};

type FlowUser record {|
    string id?;
    string username?;
    string userStoreDomain?;
    UserClaim[] claims?;
|};

type UserClaim record {|
    string uri;
    string|string[] value;
|};

type Application record {|
    string id?;
|};

type Tenant record {|
    string domain?;
|};

type Organization record {|
    string id?;
    string name?;
    string orgHandle?;
    int depth?;
|};

type AllowedOperation record {|
    string op;
    string[] paths?;
|};

// --- Outbound response types (this service → WSO2 IS) ---

type SuccessResponse record {|
    string actionStatus;
    ReplaceOperation[] operations?;
|};

type ReplaceOperation record {|
    string op;
    string path;
    string|string[] value;
|};

type FailedResponse record {|
    string actionStatus;
    string failureReason;
    string failureDescription;
|};

type ErrorResponse record {|
    string actionStatus;
    string errorMessage;
    string errorDescription;
|};

// --- Userstore API types ---

type UserstoreLookupRequest record {|
    string username;
|};

type UserstoreLookupFoundResponse record {|
    boolean exists;
    string externalId;
    string username;
    string status;
    string createdAt;
|};

type UserstoreLookupNotFoundResponse record {|
    boolean exists;
    string username;
|};
