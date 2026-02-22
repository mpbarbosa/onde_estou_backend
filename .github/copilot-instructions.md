# Copilot Instructions

## Project Overview

Serverless AWS backend for **onde estou** — a location-aware app for Brazil. Provides reverse geocoding and map configuration via AWS Location Service, exposed through API Gateway HTTP API + Lambda.

## Architecture

```text
src/
├── lambda/
│   ├── geocode-reverse/   # POST /api/geocode/reverse — converts [lat, lng] to address
│   └── map-credentials/   # GET /api/map/credentials  — returns MapLibre GL config
└── scripts/
    ├── setup-aws-infrastructure.sh  # Run once: creates AWS resources, writes src/aws-config.json
    └── deploy-backend.sh            # Packages Lambdas (npm install + zip), deploys to AWS
```

`src/aws-config.json` is **generated** by the setup script (not committed). Both deploy scripts must be run from the **repository root**, not from inside `src/`.

All AWS resources are named with the prefix `onde-estou-` (e.g. `onde-estou-geocode-reverse`, `onde-estou-map`).

## Deployment

```bash
# 1. Create AWS infrastructure (run once)
./src/scripts/setup-aws-infrastructure.sh

# 2. Deploy Lambda functions + API Gateway
./src/scripts/deploy-backend.sh
```

Prerequisites: `aws` CLI configured, `jq`, `node` 20.x, `zip`.

Override region or CORS origin:

```bash
AWS_REGION=sa-east-1 ./src/scripts/setup-aws-infrastructure.sh
ALLOWED_ORIGIN=http://localhost:3000 ./src/scripts/deploy-backend.sh
```

## Testing the API

```bash
API_ENDPOINT=$(jq -r '.apiEndpoint' src/aws-config.json)

# Reverse geocode
curl -X POST $API_ENDPOINT/api/geocode/reverse \
  -H 'Content-Type: application/json' \
  -d '{"latitude": -23.550520, "longitude": -46.633309}'

# Map config
curl $API_ENDPOINT/api/map/credentials
```

View Lambda logs:

```bash
aws logs tail /aws/lambda/onde-estou-geocode-reverse --follow
aws logs tail /aws/lambda/onde-estou-map-credentials --follow
```

## Key Conventions

- **Lambda runtime**: Node.js 20.x, CommonJS (`exports.handler`, `require()`).
- **AWS Location coordinate order**: `[longitude, latitude]` (opposite of the API's `{latitude, longitude}` input).
- **CORS**: Both Lambdas set `ALLOWED_ORIGIN` from env var (defaults to `*`). Production is locked to `https://www.mpbarbosa.com`.
- **Lambda environment variables**: `AWS_REGION`, `PLACE_INDEX_NAME` (geocode), `MAP_NAME` (map), `ALLOWED_ORIGIN`.
- **geocode-reverse** depends on `@aws-sdk/client-location` (must run `npm install --production` before zipping). **map-credentials** has no npm dependencies.
- Error handling in Lambdas maps `ResourceNotFoundException` and `AccessDeniedException` to 500 responses with descriptive messages; coordinate validation returns 400.
- The deploy script is idempotent — it updates existing Lambda functions and skips already-created API Gateway routes (errors suppressed with `|| true`).

## IAM Permissions (minimal)

Lambda role (`onde-estou-lambda-role`) allows:

- `geo:SearchPlaceIndexForPosition` on the Place Index
- `geo:GetMap*` on the Map
- `logs:*` for CloudWatch
