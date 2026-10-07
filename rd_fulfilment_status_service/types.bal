// Admin mode values
type AdminMode "NORMAL"|"DOWN"|"SLOW";

// Order line fulfilment record stored in memory
type FulfilmentLine record {|
    string key;
    string orderId;
    string lineNo;
    string status;
    string carrier?;
    string eta;
    string lastUpdated;
|};

// Successful order line lookup response
type OrderLineResponse record {|
    string key;
    string status;
    string carrier?;
    string eta;
    string lastUpdated;
|};

// Error response for invalid key format
type InvalidKeyError record {|
    string 'error = "INVALID_KEY";
    string message;
|};

// Error response for a key that was not found
type NotFoundError record {|
    string 'error = "NOT_FOUND";
    string key;
|};

// Error response for service unavailable scenarios (DOWN mode)
type ServiceUnavailableError record {|
    string 'error = "SERVICE_UNAVAILABLE";
|};

// Request body for POST /fulfilment/admin/mode
type AdminModeRequest record {|
    AdminMode mode;
    int delayMs?;
|};

// Response body for the admin mode get/set endpoints
type AdminModeResponse record {|
    AdminMode mode;
    int delayMs;
|};

// Response body for GET /fulfilment/admin/stats
type AdminStatsResponse record {|
    int totalCalls;
    map<int> byOutcome;
|};

// Internal mutable admin state, protected as a single isolated value
type AdminState record {|
    AdminMode mode;
    int delayMs;
|};

// Internal mutable stats state, protected as a single isolated value
type StatsState record {|
    int totalCalls;
    map<int> byOutcome;
|};

// Response body for POST /fulfilment/admin/reset
type AdminResetResponse record {|
    string message;
|};
