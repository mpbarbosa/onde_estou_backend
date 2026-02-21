# Architecture Overview

## System Diagram

```
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
- Dependency: `@aws-sdk/client-location` (bundled in the deployment zip via `npm install --production`).

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

## Directory Structure

```
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
