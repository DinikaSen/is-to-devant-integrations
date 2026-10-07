# RD Fulfilment Status Service

A simple, stateless-infrastructure (in-memory only) demo backend exposing
order-line fulfilment status lookups with configurable fault-injection and
admin controls. Built for product demos and designed to run locally or be
deployed to Devant.

No database, no local files — all data (seed fulfilment lines, admin mode,
forced-401 switch, call stats) lives in memory and resets whenever the
service restarts.

This service has **no authentication of its own**. Security (OAuth2) is
enforced by the Devant API gateway sitting in front of it — the service
trusts that every request it receives has already been authorized.

## Running locally

1. Make sure the Ballerina distribution referenced in `Ballerina.toml`
   (`2201.13.6`) is installed.
2. Optionally provide configurable values in a `Config.toml` file placed in
   this package directory (see **Configurables** below). Every configurable
   has a default, so the service starts with no configuration at all.
3. Run the service:

   ```bash
   bal run
   ```

4. The service starts on the configured port (default `8080`) with base path
   `/fulfilment`.

## Deploying to Devant

1. Push this package to the Git repository connected to your Devant project.
2. Create a new Devant component pointing at the `rd_fulfilment_status_service`
   directory, selecting the Ballerina service buildpack.
3. Devant auto-detects the HTTP listener and the `configurable` variables
   declared in `config.bal`. Set their values from the component's
   **Configurations** panel before (or after) the first deployment.
4. **Security is applied at the Devant gateway, not in this service.**
   Configure the Devant gateway in front of this component to enforce OAuth2
   on all routes (including `/fulfilment/admin/**`) — this service does not
   validate tokens or credentials itself.
5. Once deployed, Devant assigns a public URL for the component; use that in
   place of `http://localhost:8080` in the curl examples below.

## Configurables

| Name                  | Type | Default | Description                                                                               |
|-----------------------|------|---------|---------------------------------------------------------------------------------------------|
| `servicePort`         | int  | `8080`  | Port the HTTP listener binds to.                                                           |
| `slowOrderDelayMs`    | int  | `3000`  | Delay (ms) applied to requests whose `orderId` starts with `5` (simulated slow backend).   |
| `defaultSlowDelayMs`  | int  | `3000`  | Delay (ms) applied to every response when admin mode is `SLOW` and no `delayMs` has been set via the admin endpoint. |

Example `Config.toml`:

```toml
servicePort = 8080
slowOrderDelayMs = 3000
defaultSlowDelayMs = 3000
```

## Seed data (in memory)

| Key     | Status     | Carrier | ETA        |
|---------|------------|---------|------------|
| 1001-1  | SHIPPED    | DHL     | 2026-10-12 |
| 1002-1  | PICKING    | (none)  | 2026-10-14 |
| 5001-1  | IN_TRANSIT | UPS     | 2026-10-11 |
| 6001-1  | DELIVERED  | DHL     | 2026-10-08 |

## API

### GET /fulfilment/orderlines/{key}

`key` must be `<orderId>-<lineNo>`, digits only (e.g. `1001-1`).

- Invalid key format → `400 {"error": "INVALID_KEY", "message": "..."}`
- Found → `200 {"key", "status", "carrier", "eta", "lastUpdated"}`
- Not found → `404 {"error": "NOT_FOUND", "key": "..."}`
- Admin mode is `DOWN` → `503 {"error": "SERVICE_UNAVAILABLE"}`

This service has no 401 behaviour of its own — authentication/authorization
for all routes is enforced entirely by the Devant gateway in front of it.

The response echoes back the `X-Correlation-ID` request header (if present)
in the response headers.

### Demo triggers

- Any key whose `orderId` starts with `5` (e.g. `5001-1`) delays its response
  by `slowOrderDelayMs` (default 3000ms) — simulates a slow backend.
- Admin mode (see below) applies to every request regardless of key.

### Admin endpoints

- `POST /fulfilment/admin/mode` — body `{"mode": "NORMAL"|"DOWN"|"SLOW", "delayMs": n}`
  (`delayMs` optional, only relevant for `SLOW`).
- `GET /fulfilment/admin/mode` — returns the currently active mode and delay.
- `GET /fulfilment/admin/stats` — returns `{"totalCalls", "byOutcome": {"SUCCESS": n, "NOT_FOUND": n, ...}}`.
- `POST /fulfilment/admin/reset` — clears counters and sets mode back to
  `NORMAL`.

Admin endpoints carry no auth of their own; protect them at the Devant
gateway level, same as the data endpoint.

## Logging

Every request to `GET /fulfilment/orderlines/{key}` logs one line containing:
timestamp, key, mode/trigger applied, HTTP status, elapsed milliseconds, and
the correlation ID (or `(none)` if not supplied).

## curl examples

Replace `http://localhost:8080` with your Devant component URL when deployed.

### Found fulfilment line

```bash
curl -i http://localhost:8080/fulfilment/orderlines/1001-1
```

### Not found

```bash
curl -i http://localhost:8080/fulfilment/orderlines/9999-1
```

### Invalid key format

```bash
curl -i http://localhost:8080/fulfilment/orderlines/abc-1
```

### With correlation ID

```bash
curl -i http://localhost:8080/fulfilment/orderlines/1001-1 \
  -H "X-Correlation-ID: demo-123"
```

### Simulated slow backend (orderId starts with "5")

```bash
curl -i http://localhost:8080/fulfilment/orderlines/5001-1
```

### Set admin mode to DOWN (every request returns 503)

```bash
curl -i -X POST http://localhost:8080/fulfilment/admin/mode \
  -H "Content-Type: application/json" \
  -d '{"mode": "DOWN"}'
```

### Set admin mode to SLOW with a custom delay

```bash
curl -i -X POST http://localhost:8080/fulfilment/admin/mode \
  -H "Content-Type: application/json" \
  -d '{"mode": "SLOW", "delayMs": 5000}'
```

### Restore NORMAL mode

```bash
curl -i -X POST http://localhost:8080/fulfilment/admin/mode \
  -H "Content-Type: application/json" \
  -d '{"mode": "NORMAL"}'
```

### Get current admin mode

```bash
curl -i http://localhost:8080/fulfilment/admin/mode
```

### Get call stats

```bash
curl -i http://localhost:8080/fulfilment/admin/stats
```

### Reset counters and mode

```bash
curl -i -X POST http://localhost:8080/fulfilment/admin/reset
```
