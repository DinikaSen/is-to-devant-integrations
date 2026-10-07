# RD Order Profile Service

A simple, stateless-infrastructure (in-memory only) demo backend exposing order
line lookups with configurable fault-injection and admin controls. Built for
product demos and designed to run locally or be deployed to Devant.

No database, no local files — all data (seed order lines, admin mode, call
stats) lives in memory and resets whenever the service restarts.

## Running locally

1. Make sure the Ballerina distribution referenced in `Ballerina.toml`
   (`2201.13.6`) is installed.
2. Provide the required configurable values in a `Config.toml` file placed in
   this package directory (see **Configurables** below for the full list).
   At minimum you do not need to set anything to start the service, since
   every configurable has a default — except `basicAuthPassword`, which
   defaults to an empty string and only matters if you turn basic auth on.
3. Run the service:

   ```bash
   bal run
   ```

4. The service starts on the configured port (default `8080`) with base path
   `/profile`.

## Deploying to Devant

1. Push this package to the Git repository connected to your Devant project.
2. Create a new Devant component pointing at the `rd_order_profile_service`
   directory, selecting the Ballerina service buildpack.
3. Devant auto-detects the HTTP listener and the `configurable` variables
   declared in `config.bal`. Set their values from the component's
   **Configurations** panel before (or after) the first deployment:
   - Mark `basicAuthPassword` as a secret value in the Devant configuration
     panel.
4. Admin endpoints (`/profile/admin/**`) are not protected by any
   service-level auth — they are expected to sit behind the Devant gateway,
   which should be configured to restrict access to them (e.g. via gateway
   policies/roles) if exposed outside trusted demo operators.
5. Once deployed, Devant assigns a public URL for the component; use that in
   place of `http://localhost:8080` in the curl examples below.

## Configurables

| Name                   | Type    | Default  | Description                                                                 |
|------------------------|---------|----------|-------------------------------------------------------------------------------|
| `servicePort`          | int     | `8080`   | Port the HTTP listener binds to.                                            |
| `defaultSlowDelayMs`   | int     | `3000`   | Delay (ms) applied to every response when admin mode is `SLOW` and no `delayMs` has been set via the admin endpoint. |
| `basicAuthEnabled`     | boolean | `false`  | Turns HTTP Basic Auth on/off for the `GET /profile/orderlines/{key}` endpoint only. |
| `basicAuthUsername`    | string  | `admin`  | Username required when `basicAuthEnabled` is `true`.                        |
| `basicAuthPassword`    | string  | `""`     | Password required when `basicAuthEnabled` is `true`. Configure as a secret. |

Example `Config.toml`:

```toml
servicePort = 8080
defaultSlowDelayMs = 3000
basicAuthEnabled = false
basicAuthUsername = "admin"
basicAuthPassword = "change-me"
```

## Seed data (in memory)

| Key     | Customer | SKU   | Qty | Amount | Cost Centre |
|---------|----------|-------|-----|--------|-------------|
| 1001-1  | ACME     | A-100 | 2   | 40.00  | CC-4410     |
| 1002-1  | ACME     | B-200 | 1   | 12.50  | CC-4410     |
| 5001-1  | GLOBEX   | C-300 | 5   | 99.00  | CC-5520     |
| 6001-1  | INITECH  | D-400 | 3   | 21.00  | CC-4410     |

Note: any key whose `orderId` starts with `6` (e.g. `6001-1`) always returns
`503 SERVICE_UNAVAILABLE`, regardless of seed data, to simulate backend A
being down.

## API

### GET /profile/orderlines/{key}

`key` must be `<orderId>-<lineNo>`, digits only (e.g. `1001-1`).

- Invalid key format → `400 {"error": "INVALID_KEY", "message": "..."}`
- Found → `200 {"key", "orderId", "lineNo", "customer", "sku", "qty", "amount", "costCentre"}`
- Not found → `404 {"error": "NOT_FOUND", "key": "..."}`
- `orderId` starts with `6`, or admin mode is `DOWN` → `503 {"error": "SERVICE_UNAVAILABLE"}`
- Basic auth enabled and credentials missing/invalid → `401`

The response echoes back the `X-Correlation-ID` request header (if present)
in the response headers.

### Admin endpoints

- `POST /profile/admin/mode` — body `{"mode": "NORMAL"|"DOWN"|"SLOW", "delayMs": n}` (`delayMs` optional, only relevant for `SLOW`).
- `GET /profile/admin/mode` — returns the currently active mode and delay.
- `GET /profile/admin/stats` — returns `{"totalCalls": n, "byOutcome": {"SUCCESS": n, "NOT_FOUND": n, ...}}`.
- `POST /profile/admin/reset` — resets the in-memory call stats to zero.

Admin endpoints carry no auth of their own; protect them at the Devant
gateway level.

## Logging

Every request to `GET /profile/orderlines/{key}` logs one line containing:
timestamp, key, mode applied, HTTP status, elapsed milliseconds, and the
correlation ID (or `(none)` if not supplied).

## curl examples

Replace `http://localhost:8080` with your Devant component URL when deployed.

### Found order line

```bash
curl -i http://localhost:8080/profile/orderlines/1001-1
```

### Not found

```bash
curl -i http://localhost:8080/profile/orderlines/9999-1
```

### Invalid key format

```bash
curl -i http://localhost:8080/profile/orderlines/abc-1
```

### Simulated backend outage (orderId starts with "6")

```bash
curl -i http://localhost:8080/profile/orderlines/6001-1
```

### With correlation ID

```bash
curl -i http://localhost:8080/profile/orderlines/1001-1 \
  -H "X-Correlation-ID: demo-123"
```

### With basic auth (when basicAuthEnabled = true)

```bash
curl -i -u admin:change-me http://localhost:8080/profile/orderlines/1001-1
```

### Set admin mode to DOWN (every request returns 503)

```bash
curl -i -X POST http://localhost:8080/profile/admin/mode \
  -H "Content-Type: application/json" \
  -d '{"mode": "DOWN"}'
```

### Set admin mode to SLOW with a custom delay

```bash
curl -i -X POST http://localhost:8080/profile/admin/mode \
  -H "Content-Type: application/json" \
  -d '{"mode": "SLOW", "delayMs": 5000}'
```

### Restore NORMAL mode

```bash
curl -i -X POST http://localhost:8080/profile/admin/mode \
  -H "Content-Type: application/json" \
  -d '{"mode": "NORMAL"}'
```

### Get current admin mode

```bash
curl -i http://localhost:8080/profile/admin/mode
```

### Get call stats

```bash
curl -i http://localhost:8080/profile/admin/stats
```

### Reset stats

```bash
curl -i -X POST http://localhost:8080/profile/admin/reset
```
