import ballerina/lang.array;
import ballerina/lang.regexp;
import ballerina/log;
import ballerina/time;

final regexp:RegExp orderLineKeyPattern = re `^[0-9]+-[0-9]+$`;

// Validate the order line key format: digits-digits only
isolated function isValidKeyFormat(string key) returns boolean {
    return orderLineKeyPattern.isFullMatch(key);
}

// Split a valid key into orderId and lineNo parts
isolated function splitKey(string key) returns [string, string] {
    string[] parts = regexp:split(re `-`, key);
    return [parts[0], parts[1]];
}

// Read the current admin mode snapshot
isolated function getAdminState() returns AdminModeResponse {
    lock {
        return adminState.clone();
    }
}

// Update the admin mode and optional delay
isolated function setAdminState(AdminMode mode, int? delayMs) returns AdminModeResponse {
    lock {
        adminState.mode = mode;
        if delayMs is int {
            adminState.delayMs = delayMs;
        }
        return adminState.clone();
    }
}

// Record a processed call outcome for stats
isolated function recordOutcome(string outcome) {
    lock {
        statsState.totalCalls += 1;
        int current = statsState.byOutcome[outcome] ?: 0;
        statsState.byOutcome[outcome] = current + 1;
    }
}

// Read the current stats snapshot
isolated function getStatsSnapshot() returns AdminStatsResponse {
    lock {
        return statsState.clone();
    }
}

// Reset stats counters to zero
isolated function resetStats() {
    lock {
        statsState.totalCalls = 0;
        statsState.byOutcome.removeAll();
    }
}

// Validate HTTP basic auth credentials from the Authorization header
isolated function isAuthorized(string? authorizationHeader) returns boolean {
    if authorizationHeader is () {
        return false;
    }
    if !authorizationHeader.startsWith("Basic ") {
        return false;
    }
    string encodedPart = authorizationHeader.substring(6);
    byte[]|error decoded = array:fromBase64(encodedPart);
    if decoded is error {
        return false;
    }
    string|error decodedStr = string:fromBytes(decoded);
    if decodedStr is error {
        return false;
    }
    int? separatorIndex = decodedStr.indexOf(":");
    if separatorIndex is () {
        return false;
    }
    string suppliedUsername = decodedStr.substring(0, separatorIndex);
    string suppliedPassword = decodedStr.substring(separatorIndex + 1);
    return suppliedUsername == basicAuthUsername && suppliedPassword == basicAuthPassword;
}

// Look up an order line by key; returns the found record or nil
isolated function findOrderLine(string key) returns OrderLine? {
    return orderLineStore[key];
}

// Log a single line per request
isolated function logRequest(string key, string modeApplied, int statusCode, int elapsedMs, string? correlationId) {
    log:printInfo("request processed",
        timestamp = time:utcToString(time:utcNow()),
        key = key,
        modeApplied = modeApplied,
        status = statusCode,
        elapsedMs = elapsedMs,
        correlationId = correlationId ?: "(none)"
    );
}
