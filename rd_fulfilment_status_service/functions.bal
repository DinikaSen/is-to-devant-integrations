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
        return {mode: adminState.mode, delayMs: adminState.delayMs};
    }
}

// Update the admin mode and optional delay
isolated function setAdminState(AdminMode mode, int? delayMs) returns AdminModeResponse {
    lock {
        adminState.mode = mode;
        if delayMs is int {
            adminState.delayMs = delayMs;
        }
        return {mode: adminState.mode, delayMs: adminState.delayMs};
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
        return {
            totalCalls: statsState.totalCalls,
            byOutcome: statsState.byOutcome.clone()
        };
    }
}

// Reset stats counters and admin mode to NORMAL
isolated function resetAll() {
    lock {
        statsState.totalCalls = 0;
        statsState.byOutcome.removeAll();
    }
    lock {
        adminState.mode = "NORMAL";
    }
}

// Look up a fulfilment line by key; returns the found record or nil
isolated function findFulfilmentLine(string key) returns FulfilmentLine? {
    return fulfilmentLineStore[key];
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
