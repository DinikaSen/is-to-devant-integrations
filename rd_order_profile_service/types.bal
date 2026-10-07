// Admin mode values
type AdminMode "NORMAL"|"DOWN"|"SLOW";

// Order line record stored in memory
type OrderLine record {|
    string key;
    string orderId;
    string lineNo;
    string customer;
    string sku;
    int qty;
    decimal amount;
    string costCentre;
|};

// Successful order line lookup response
type OrderLineResponse record {|
    string key;
    string orderId;
    string lineNo;
    string customer;
    string sku;
    int qty;
    decimal amount;
    string costCentre;
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

// Error response for service unavailable scenarios (DOWN mode or simulated backend outage)
type ServiceUnavailableError record {|
    string 'error = "SERVICE_UNAVAILABLE";
|};

// Request body for POST /profile/admin/mode
type AdminModeRequest record {|
    AdminMode mode;
    int delayMs?;
|};

// Response body for the admin mode get/set endpoints
type AdminModeResponse record {|
    AdminMode mode;
    int delayMs;
|};

// Response body for GET /profile/admin/stats
type AdminStatsResponse record {|
    int totalCalls;
    map<int> byOutcome;
|};

// Internal mutable stats state, protected as a single isolated value
type StatsState record {|
    int totalCalls;
    map<int> byOutcome;
|};

// Response body for POST /profile/admin/reset
type AdminResetResponse record {|
    string message;
|};

// Generic bad request error body
type BadRequestError record {|
    string 'error;
    string message;
|};

// Unauthorized response body
type UnauthorizedError record {|
    string 'error = "UNAUTHORIZED";
    string message;
|};
