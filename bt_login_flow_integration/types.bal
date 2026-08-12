// Inbound request
type LoginDecisionRequest record {|
    string username;
    string ipAddress;
|};

// Userstore API types
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

// Risk API types
type RiskEvaluateRequest record {|
    string username;
    string ipAddress;
|};

type RiskEvaluateResponse record {|
    boolean allow;
    int score;
    string riskLevel;
    string[] reasons?;
|};

// Login decision response sub-objects
type UserStoreInfo record {|
    boolean exists;
    string externalId?;
|};

type RiskInfo record {|
    boolean allow;
    int score;
|};

// Final response
type LoginDecisionResponse record {|
    string decision;
    string reason;
    UserStoreInfo userStore;
    RiskInfo risk?;
|};
