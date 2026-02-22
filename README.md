# onde_estou_backend — AWS Location Based Service

Serverless AWS backend for **onde estou** — a location-aware app for Brazil.  
Provides reverse geocoding and map configuration via **AWS Location Service**, exposed through **API Gateway HTTP API + Lambda**.

---

## Table of Contents

- [Architecture](#architecture)
- [Provisioned AWS Resources](#provisioned-aws-resources)
- [Live API Endpoints](#live-api-endpoints)
- [Prerequisites](#prerequisites)
- [Deployment](#deployment)
- [API Reference](#api-reference)
- [Environment Variables](#environment-variables)
- [IAM & Security](#iam--security)
- [Monitoring](#monitoring)
- [Cost Estimate](#cost-estimate)
- [Troubleshooting](#troubleshooting)
- [Cleanup](#cleanup)

---

## Architecture

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

### Repository layout

```text
onde_estou_backend/
├── setup-aws-lbs.sh                      # Convenience wrapper — runs Step 1 then Step 2
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
│   │   └── deploy-backend.sh             # Step 2 — package & deploy Lambda + API GW
│   ├── aws-config.json                   # Generated config (not committed)
│   └── aws-config.example.json           # Template showing expected aws-config.json format
└── README.md
```

---

## Provisioned AWS Resources

The following resources were created in **us-east-1** under account `655139684612`.

| Resource | Name | ARN |
|---|---|---|
| Location Map | `onde-estou-map` | `arn:aws:geo:us-east-1:655139684612:map/onde-estou-map` |
| Place Index | `onde-estou-place-index` | `arn:aws:geo:us-east-1:655139684612:place-index/onde-estou-place-index` |
| Lambda IAM Role | `onde-estou-lambda-role` | `arn:aws:iam::655139684612:role/onde-estou-lambda-role` |
| IAM Policy | `onde-estou-location-policy` | `arn:aws:iam::655139684612:policy/onde-estou-location-policy` |
| Lambda Function | `onde-estou-geocode-reverse` | `arn:aws:lambda:us-east-1:655139684612:function:onde-estou-geocode-reverse` |
| Lambda Function | `onde-estou-map-credentials` | `arn:aws:lambda:us-east-1:655139684612:function:onde-estou-map-credentials` |
| API Gateway HTTP API | `onde-estou-api` | ID: `b2inkriw8k` |

**Map style**: VectorEsriNavigation  
**Place Index data provider**: Esri (covers Brazil with high accuracy)

---

## Live API Endpoints

| Method | URL | Description |
|---|---|---|
| `POST` | `https://b2inkriw8k.execute-api.us-east-1.amazonaws.com/api/geocode/reverse` | Reverse geocode coordinates → address |
| `GET` | `https://b2inkriw8k.execute-api.us-east-1.amazonaws.com/api/map/credentials` | MapLibre GL JS map configuration |

### Quick test

```bash
API_ENDPOINT=https://b2inkriw8k.execute-api.us-east-1.amazonaws.com

# Reverse geocode — São Paulo city centre
curl -X POST $API_ENDPOINT/api/geocode/reverse \
  -H 'Content-Type: application/json' \
  -d '{"latitude": -23.550520, "longitude": -46.633309}'

# Map configuration
curl $API_ENDPOINT/api/map/credentials
```

---

## Prerequisites

| Tool | Version | Purpose |
|---|---|---|
| AWS CLI | 2.x+ | Provision & manage AWS resources |
| Node.js | 20.x | Lambda runtime & local packaging |
| `jq` | any | JSON parsing in shell scripts |
| `zip` | any | Packaging Lambda deployment bundles |

```bash
aws --version   # Verify AWS CLI
node --version  # Should be v20.x
jq --version
```

---

## Deployment

All scripts must be run from the **repository root**. If you cloned the repository and the scripts are not executable, run:

```bash
chmod +x setup-aws-lbs.sh src/scripts/*.sh
```

### Quick start (one command)

```bash
./setup-aws-lbs.sh
```

`setup-aws-lbs.sh` is a convenience wrapper that runs **Step 1** (infrastructure setup) followed by **Step 2** (Lambda + API Gateway deploy) in sequence. It accepts the same environment variable overrides as the individual scripts:

```bash
AWS_REGION=sa-east-1 ALLOWED_ORIGIN=http://localhost:3000 ./setup-aws-lbs.sh
```

Use the individual scripts below if you need to run the steps separately.

### Step 1 — Create AWS infrastructure (run once)

```bash
./src/scripts/setup-aws-infrastructure.sh
```

Creates:

- AWS Location Service Map (`onde-estou-map`, style `VectorEsriNavigation`)
- AWS Location Service Place Index (`onde-estou-place-index`)
- IAM Lambda execution role (`onde-estou-lambda-role`)
- IAM policy (`onde-estou-location-policy`) with least-privilege permissions
- Writes `src/aws-config.json` with all resource ARNs

> **Note — manual IAM step**: The script may not be able to grant `iam:PassRole` automatically. If prompted, attach the following inline policy to your IAM user or role:
>
> ```json
> {
>   "Version": "2012-10-17",
>   "Statement": [{
>     "Effect": "Allow",
>     "Action": "iam:PassRole",
>     "Resource": "arn:aws:iam::655139684612:role/onde-estou-lambda-role",
>     "Condition": {
>       "StringEquals": { "iam:PassedToService": "lambda.amazonaws.com" }
>     }
>   }]
> }
> ```

### Step 2 — Deploy Lambda functions & API Gateway

```bash
./src/scripts/deploy-backend.sh
```

Performs:

1. `npm install --production` + `zip` for `geocode-reverse` (needs `@aws-sdk/client-location`)
2. `zip` for `map-credentials` (no npm dependencies)
3. Creates or updates both Lambda functions (Node.js 20.x runtime)
4. Creates or updates API Gateway HTTP API with routes and CORS
5. Configures Lambda resource-based permissions for API Gateway
6. Updates `src/aws-config.json` with the API endpoint

The script is **idempotent** — re-running it updates existing resources safely.

### Override defaults

```bash
# Different region
AWS_REGION=sa-east-1 ./src/scripts/setup-aws-infrastructure.sh

# Custom CORS origin for local development
ALLOWED_ORIGIN=http://localhost:3000 ./src/scripts/deploy-backend.sh
```

---

## API Reference

### POST /api/geocode/reverse

Converts a latitude/longitude pair to a postal address using AWS Location Service.

#### Request body

```json
{
  "latitude": -23.550520,
  "longitude": -46.633309
}
```

#### Response — 200 OK

```json
{
  "provider": "aws-location-service",
  "coordinates": {
    "latitude": -23.550520,
    "longitude": -46.633309
  },
  "address": {
    "label": "Av. Paulista, 1578, São Paulo, SP",
    "street": "Avenida Paulista",
    "addressNumber": "1578",
    "neighborhood": "Bela Vista",
    "municipality": "São Paulo",
    "region": "São Paulo",
    "country": "BRA",
    "postalCode": "01310-200"
  }
}
```

#### Error responses

| Status | Cause |
|---|---|
| `400` | Missing or invalid `latitude`/`longitude` |
| `404` | No address found for the given coordinates |
| `500` | AWS Location Service error (AccessDenied, ResourceNotFound) |

> **Coordinate order**: AWS Location Service expects `[longitude, latitude]`. The Lambda handler reverses the frontend's `{latitude, longitude}` input automatically.

---

### GET /api/map/credentials

Returns the MapLibre GL JS map configuration (style URL, region, defaults).

#### Response — 200 OK (map credentials)

```json
{
  "mapName": "onde-estou-map",
  "style": "VectorEsriNavigation",
  "mapLibre": {
    "version": "4.0.0",
    "styleUrl": "https://maps.geo.us-east-1.amazonaws.com/maps/v0/maps/onde-estou-map/style-descriptor"
  },
  "defaults": {
    "center": [-46.633309, -23.550520],
    "zoom": 12
  }
}
```

---

## Environment Variables

Automatically set by `deploy-backend.sh`. Can be overridden per function in the Lambda console.

| Variable | Lambda | Value |
|---|---|---|
| `AWS_REGION` | both | `us-east-1` |
| `PLACE_INDEX_NAME` | geocode-reverse | `onde-estou-place-index` |
| `MAP_NAME` | map-credentials | `onde-estou-map` |
| `ALLOWED_ORIGIN` | both | `https://www.mpbarbosa.com` (production) |

---

## IAM & Security

### Lambda execution role — minimal permissions

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "geo:SearchPlaceIndexForPosition",
      "Resource": "arn:aws:geo:us-east-1:655139684612:place-index/onde-estou-place-index"
    },
    {
      "Effect": "Allow",
      "Action": "geo:GetMap*",
      "Resource": "arn:aws:geo:us-east-1:655139684612:map/onde-estou-map"
    },
    {
      "Effect": "Allow",
      "Action": ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
      "Resource": "*"
    }
  ]
}
```

### CORS

Both Lambdas read `ALLOWED_ORIGIN` at runtime and set it as the `Access-Control-Allow-Origin` response header.

- **Production**: `https://www.mpbarbosa.com`
- **Development**: set `ALLOWED_ORIGIN=http://localhost:3000` before running the deploy script

---

## CI / Continuous Integration

A GitHub Actions workflow (`.github/workflows/ci.yml`) runs automatically on every push and pull request to `main`. It has three jobs:

| Job | What it checks |
|---|---|
| `lint-markdown` | All `*.md` files via `mdl` (uses `.mdlrc` + `.mdl_style.rb`) |
| `lint-shell` | All `*.sh` scripts via `shellcheck` |
| `validate-lambda-deps` | `npm install --production` succeeds for both Lambda packages |

No AWS credentials are required — the workflow validates only local artifacts. Deployment to AWS remains a manual step via the shell scripts.

---

## Monitoring

### Live log streaming

```bash
# Geocode function
aws logs tail /aws/lambda/onde-estou-geocode-reverse --follow

# Map credentials function
aws logs tail /aws/lambda/onde-estou-map-credentials --follow
```

### CloudWatch metrics

Navigate to **CloudWatch → Metrics → Lambda** in the AWS console to view:

- Invocations, Errors, Throttles
- Duration (P50, P95, P99)

---

## Cost Estimate

AWS Location Service pricing (us-east-1):

| Service | Price |
|---|---|
| Maps | $4.00 per 1,000 tile requests |
| Geocoding | $4.00 per 1,000 requests |
| Lambda | $0.20 per 1M requests (first 1M free) |
| API Gateway HTTP API | $1.00 per 1M requests (first 1M free) |

**Example — 10,000 requests/month**  
Maps: $0.04 · Geocoding: $0.04 · Lambda: $0.00 · API GW: $0.00 → **~$0.08/month**

Free tier covers all development and light production use.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `ResourceNotFoundException` in Lambda logs | Function or Location resource not found | Re-run `deploy-backend.sh` |
| `AccessDeniedException` in Lambda logs | IAM policy not attached | Run setup script; verify `onde-estou-location-policy` is attached to `onde-estou-lambda-role` |
| CORS error in browser | `ALLOWED_ORIGIN` mismatch | Update Lambda env var `ALLOWED_ORIGIN` to match your frontend origin |
| Geocode returns 404 | No address data for coordinates | Coordinates may be in a remote/ocean area; AWS Location coverage varies |
| `iam:PassRole` error during setup | Deployer lacks PassRole permission | Attach the inline policy shown in the [Step 1 note](#step-1--create-aws-infrastructure-run-once) |
| Script exits with `Permission denied` | Script not executable | Run `chmod +x setup-aws-lbs.sh src/scripts/*.sh` |

### Script exit codes

Both `setup-aws-infrastructure.sh` and `deploy-backend.sh` use a consistent exit code convention:

| Exit code | Meaning |
|---|---|
| `0` | Success — all steps completed |
| `1` | Failure — missing prerequisite tool, missing `src/aws-config.json`, or an AWS CLI command returned an error |

When a script exits with code 1 it prints a descriptive error line before exiting. For a full command trace, re-run with:

```bash
bash -x src/scripts/deploy-backend.sh
```

---

## Cleanup

Remove all AWS resources to avoid charges:

```bash
# Read config
API_ID=$(jq -r '.apiId' src/aws-config.json)
POLICY_ARN=$(jq -r '.policyArn' src/aws-config.json)

# API Gateway
aws apigatewayv2 delete-api --api-id $API_ID

# Lambda functions
aws lambda delete-function --function-name onde-estou-geocode-reverse
aws lambda delete-function --function-name onde-estou-map-credentials

# Location Service resources
aws location delete-map --map-name onde-estou-map
aws location delete-place-index --index-name onde-estou-place-index

# IAM (detach policy before deleting)
aws iam detach-role-policy --role-name onde-estou-lambda-role --policy-arn $POLICY_ARN
aws iam delete-policy --policy-arn $POLICY_ARN
aws iam delete-role --role-name onde-estou-lambda-role
```

---

**Region**: us-east-1 &nbsp;·&nbsp; **Runtime**: Node.js 20.x &nbsp;·&nbsp; **Last deployed**: 2026-02-19
