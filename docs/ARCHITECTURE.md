# Architecture Overview

## System Diagram

```text
Client (frontend)
      │
      ▼
API Gateway HTTP API  (onde-estou-api)
      │
      ├── POST /api/geocode/reverse ──► Lambda: onde-estou-geocode-reverse
      │                                        │
      │                                        ▼
      │                              AWS Location Service
      │                              Place Index (onde-estou-place-index)
      │
      └── GET  /api/map/credentials ──► Lambda: onde-estou-map-credentials
                                               │
                                               ▼
                                     AWS Location Service
                                     Map (onde-estou-map)
```

## Components

### API Gateway HTTP API (`onde-estou-api`)

- Lightweight HTTP API (not REST API) for lower latency and cost.
- CORS configured at the API level; Lambdas also set `Access-Control-Allow-Origin` for defence-in-depth.
- Routes invoke Lambda functions via AWS_PROXY integration.

### Lambda: `onde-estou-geocode-reverse`

- Runtime: **Node.js 20.x**, CommonJS.
- Accepts `{latitude, longitude}`, reverses coordinate order, calls `SearchPlaceIndexForPosition`.
- Dependency: `@aws-sdk/client-location` (bundled in the deployment zip via `npm ci --omit=dev`).

### Lambda: `onde-estou-map-credentials`

- Runtime: **Node.js 20.x**, CommonJS.
- Returns static map configuration; no outbound AWS calls at runtime.
- No npm dependencies — zipped directly.

### AWS Location Service

- **Place Index** (`onde-estou-place-index`): Esri data provider, optimised for Brazilian addresses.
- **Map** (`onde-estou-map`): Style `VectorEsriNavigation`, served directly to MapLibre GL JS clients via the style URL.

### IAM

- Single execution role (`onde-estou-lambda-role`) shared by both Lambdas.
- Least-privilege policy (`onde-estou-location-policy`): `geo:SearchPlaceIndexForPosition`, `geo:GetMap*`, and CloudWatch Logs.
- `geo:GetMap*` covers the four map tile operations (`GetMapGlyphs`, `GetMapSprites`, `GetMapStyleDescriptor`, `GetMapTile`) scoped to the specific Map ARN — no broader wildcard.

### Security Model

- **No authorizer** — the API is intentionally public. Both endpoints return only geocoding results and static map configuration; no user data or secrets are exposed.
- **CORS as browser boundary** — `ALLOWED_ORIGIN` restricts browser-initiated cross-origin requests to the production frontend (`https://www.mpbarbosa.com`). Set this variable before running `deploy-backend.sh`.
- **Rate limiting** — API Gateway HTTP API applies default throttling (10,000 requests/second burst, 5,000 requests/second steady-state). No additional throttling is configured.
- **No secrets in responses** — Lambda functions read AWS credentials from the execution role at runtime; no credentials or internal ARNs are included in API responses.

## Directory Structure

```text
onde_estou_backend/
├── src/
│   ├── lambda/
│   │   ├── geocode-reverse/        # POST /api/geocode/reverse
│   │   │   ├── index.js            # Lambda handler (CommonJS)
│   │   │   └── package.json        # Depends on @aws-sdk/client-location
│   │   └── map-credentials/        # GET /api/map/credentials
│   │       ├── index.js            # Lambda handler (no npm deps)
│   │       └── package.json
│   ├── scripts/
│   │   ├── setup-aws-infrastructure.sh   # Step 1 — create AWS resources
│   │   └── deploy-backend.sh             # Step 2 — package & deploy
│   └── aws-config.json                   # Generated (not committed)
├── docs/
│   ├── API.md
│   ├── ARCHITECTURE.md
│   └── GETTING_STARTED.md
├── CHANGELOG.md
├── CONTRIBUTING.md
└── README.md
```

## Design Decisions

- **Pure serverless**: No always-on servers; Lambda + API Gateway scales to zero.
- **CommonJS over ESM**: Lambda Node.js 20.x supports both; CommonJS avoids bundler complexity for these small handlers.
- **Idempotent deploy script**: `deploy-backend.sh` can be re-run safely; existing resources are updated, not recreated.
- **No hardcoded secrets**: All configuration flows through environment variables set by the deploy script.
- **Coordinate order handled server-side**: The API accepts `{latitude, longitude}` (natural for frontends); the Lambda reverses to `[longitude, latitude]` as required by AWS Location Service.
