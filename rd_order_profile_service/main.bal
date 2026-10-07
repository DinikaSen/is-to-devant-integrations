import ballerina/http;
import ballerina/lang.runtime;
import ballerina/time;

listener http:Listener httpListener = check new (servicePort);

service /profile on httpListener {

    // GET /profile/orderlines/{key}
    isolated resource function get orderlines/[string key](http:Request request, @http:Header string? x\-correlation\-id = ())
            returns http:Ok|http:BadRequest|http:NotFound|http:ServiceUnavailable|http:Unauthorized {
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

        // Simulated backend outage: any orderId starting with "6"
        [string, string] [orderId, _] = splitKey(key);
        if orderId.startsWith("6") {
            int elapsed = elapsedMillis(startTime);
            recordOutcome("SERVICE_UNAVAILABLE");
            logRequest(key, currentMode, 503, elapsed, correlationId);
            return buildServiceUnavailable(correlationId);
        }

        // Optional basic auth on the data endpoint
        if basicAuthEnabled {
            string? authHeaderValue = extractAuthorizationHeader(request);
            boolean authorized = isAuthorized(authHeaderValue);
            if !authorized {
                int elapsed = elapsedMillis(startTime);
                recordOutcome("UNAUTHORIZED");
                logRequest(key, currentMode, 401, elapsed, correlationId);
                map<string> unauthorizedHeaders = buildCorrelationHeaders(correlationId);
                unauthorizedHeaders["WWW-Authenticate"] = "Basic realm=\"profile\"";
                UnauthorizedError unauthorizedBody = {message: "Missing or invalid credentials"};
                http:Unauthorized unauthorizedResponse = {
                    body: unauthorizedBody,
                    headers: unauthorizedHeaders
                };
                return unauthorizedResponse;
            }
        }

        // Lookup
        OrderLine? found = findOrderLine(key);
        int elapsed = elapsedMillis(startTime);
        if found is () {
            recordOutcome("NOT_FOUND");
            logRequest(key, currentMode, 404, elapsed, correlationId);
            NotFoundError notFoundBody = {key: key};
            http:NotFound notFound = {
                body: notFoundBody,
                headers: buildCorrelationHeaders(correlationId)
            };
            return notFound;
        }

        recordOutcome("SUCCESS");
        logRequest(key, currentMode, 200, elapsed, correlationId);
        OrderLineResponse responseBody = {
            key: found.key,
            orderId: found.orderId,
            lineNo: found.lineNo,
            customer: found.customer,
            sku: found.sku,
            qty: found.qty,
            amount: found.amount,
            costCentre: found.costCentre
        };
        http:Ok okResponse = {
            body: responseBody,
            headers: buildCorrelationHeaders(correlationId)
        };
        return okResponse;
    }

    // POST /profile/admin/mode
    isolated resource function post admin/mode(@http:Payload AdminModeRequest modeReq) returns AdminModeResponse {
        return setAdminState(modeReq.mode, modeReq?.delayMs);
    }

    // GET /profile/admin/mode
    isolated resource function get admin/mode() returns AdminModeResponse {
        return getAdminState();
    }

    // GET /profile/admin/stats
    isolated resource function get admin/stats() returns AdminStatsResponse {
        return getStatsSnapshot();
    }

    // POST /profile/admin/reset
    isolated resource function post admin/reset() returns AdminResetResponse {
        resetStats();
        return {message: "Stats reset successfully"};
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

isolated function extractAuthorizationHeader(http:Request request) returns string? {
    string|http:HeaderNotFoundError authHeader = request.getHeader("Authorization");
    if authHeader is string {
        return authHeader;
    }
    return ();
}
