import ballerina/http;
import ballerina/lang.runtime;
import ballerina/time;

listener http:Listener httpListener = check new (servicePort);

service /fulfilment on httpListener {

    // GET /fulfilment/orderlines/{key}
    isolated resource function get orderlines/[string key](@http:Header string? x\-correlation\-id = ())
            returns http:Ok|http:BadRequest|http:NotFound|http:ServiceUnavailable {
        time:Utc startTime = time:utcNow();
        string? correlationId = x\-correlation\-id;

        // Admin DOWN mode: short-circuit every request
        AdminModeResponse currentAdminState = getAdminState();
        AdminMode currentMode = currentAdminState.mode;

        if currentMode == "DOWN" {
            int elapsed = elapsedMillis(startTime);
            recordOutcome("SERVICE_UNAVAILABLE");
            logRequest(key, currentMode, 503, elapsed, correlationId);
            return buildServiceUnavailable(correlationId);
        }

        // Admin SLOW mode: delay the response
        if currentMode == "SLOW" {
            decimal delaySeconds = <decimal>currentAdminState.delayMs / 1000;
            runtime:sleep(delaySeconds);
        }

        // Validate key format
        boolean validFormat = isValidKeyFormat(key);
        if !validFormat {
            int elapsed = elapsedMillis(startTime);
            recordOutcome("INVALID_KEY");
            logRequest(key, currentMode, 400, elapsed, correlationId);
            InvalidKeyError invalidKeyBody = {
                message: string `Key '${key}' is invalid. Expected format <orderId>-<lineNo> with digits only.`
            };
            http:BadRequest badRequest = {
                body: invalidKeyBody,
                headers: buildCorrelationHeaders(correlationId)
            };
            return badRequest;
        }

        // Demo trigger: orderId starting with "5" delays the response (simulated slow backend)
        [string, string] [orderId, _] = splitKey(key);
        string triggerApplied = currentMode;
        if orderId.startsWith("5") {
            decimal delaySeconds = <decimal>slowOrderDelayMs / 1000;
            runtime:sleep(delaySeconds);
            triggerApplied = "SLOW_ORDER";
        }

        // Lookup
        FulfilmentLine? found = findFulfilmentLine(key);
        int elapsed = elapsedMillis(startTime);
        if found is () {
            recordOutcome("NOT_FOUND");
            logRequest(key, triggerApplied, 404, elapsed, correlationId);
            NotFoundError notFoundBody = {key: key};
            http:NotFound notFound = {
                body: notFoundBody,
                headers: buildCorrelationHeaders(correlationId)
            };
            return notFound;
        }

        recordOutcome("SUCCESS");
        logRequest(key, triggerApplied, 200, elapsed, correlationId);
        OrderLineResponse responseBody = {
            key: found.key,
            status: found.status,
            carrier: found?.carrier,
            eta: found.eta,
            lastUpdated: found.lastUpdated
        };
        http:Ok okResponse = {
            body: responseBody,
            headers: buildCorrelationHeaders(correlationId)
        };
        return okResponse;
    }

    // POST /fulfilment/admin/mode
    isolated resource function post admin/mode(@http:Payload AdminModeRequest modeReq) returns AdminModeResponse {
        return setAdminState(modeReq.mode, modeReq?.delayMs);
    }

    // GET /fulfilment/admin/mode
    isolated resource function get admin/mode() returns AdminModeResponse {
        return getAdminState();
    }

    // GET /fulfilment/admin/stats
    isolated resource function get admin/stats() returns AdminStatsResponse {
        return getStatsSnapshot();
    }

    // POST /fulfilment/admin/reset
    isolated resource function post admin/reset() returns AdminResetResponse {
        resetAll();
        return {message: "Counters and mode reset successfully"};
    }
}

isolated function elapsedMillis(time:Utc startTime) returns int {
    time:Utc endTime = time:utcNow();
    decimal diffSeconds = time:utcDiffSeconds(endTime, startTime);
    return <int>(diffSeconds * 1000);
}

isolated function buildCorrelationHeaders(string? correlationId) returns map<string> {
    if correlationId is string {
        return {"X-Correlation-ID": correlationId};
    }
    return {};
}

isolated function buildServiceUnavailable(string? correlationId) returns http:ServiceUnavailable {
    ServiceUnavailableError serviceUnavailableBody = {};
    http:ServiceUnavailable serviceUnavailable = {
        body: serviceUnavailableBody,
        headers: buildCorrelationHeaders(correlationId)
    };
    return serviceUnavailable;
}
