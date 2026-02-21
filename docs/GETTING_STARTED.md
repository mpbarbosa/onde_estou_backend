# Getting Started

## Prerequisites

| Tool | Version | Purpose |
|---|---|---|
| AWS CLI | 2.x+ | Provision & manage AWS resources |
| Node.js | 20.x | Lambda packaging |
| `jq` | any | JSON parsing in shell scripts |
| `zip` | any | Lambda deployment bundle creation |

```bash
aws --version   # Verify AWS CLI
node --version  # Should be v20.x
jq --version
```

Your AWS credentials must be configured with permissions to create IAM roles/policies, Lambda functions, API Gateway APIs, and AWS Location Service resources:

```bash
aws configure
```

## Installation

```bash
git clone https://github.com/mpbarbosa/onde_estou_backend.git
cd onde_estou_backend
```

## Step 1 — Provision AWS Infrastructure (run once)

```bash
./src/scripts/setup-aws-infrastructure.sh
```

This creates:
- AWS Location Service Map (`onde-estou-map`)
- AWS Location Service Place Index (`onde-estou-place-index`)
- IAM execution role (`onde-estou-lambda-role`) and policy
- `src/aws-config.json` with all resource ARNs and IDs

> **Manual IAM step**: If you see an `iam:PassRole` error, attach the inline policy shown in the [README](../README.md#step-1--create-aws-infrastructure-run-once) to your IAM user.

To use a different region:

```bash
AWS_REGION=sa-east-1 ./src/scripts/setup-aws-infrastructure.sh
```

## Step 2 — Deploy Lambda Functions & API Gateway

```bash
./src/scripts/deploy-backend.sh
```

This packages the Lambdas, creates/updates the functions, and configures API Gateway routes. Re-running is safe — the script is idempotent.

For local development with a different CORS origin:

```bash
ALLOWED_ORIGIN=http://localhost:3000 ./src/scripts/deploy-backend.sh
```

## Verify the Deployment

```bash
API_ENDPOINT=$(jq -r '.apiEndpoint' src/aws-config.json)

# Reverse geocode — São Paulo city centre
curl -X POST $API_ENDPOINT/api/geocode/reverse \
  -H 'Content-Type: application/json' \
  -d '{"latitude": -23.550520, "longitude": -46.633309}'

# Map configuration
curl $API_ENDPOINT/api/map/credentials
```

## View Logs

```bash
aws logs tail /aws/lambda/onde-estou-geocode-reverse --follow
aws logs tail /aws/lambda/onde-estou-map-credentials --follow
```

## Troubleshooting

| Symptom | Fix |
|---|---|
| `ResourceNotFoundException` in logs | Re-run `deploy-backend.sh` |
| `AccessDeniedException` in logs | Verify `onde-estou-location-policy` is attached to `onde-estou-lambda-role` |
| CORS error in browser | Update `ALLOWED_ORIGIN` env var on the Lambda to match your frontend origin |
| Geocode returns 404 | Coordinates may be in a remote area with no Esri coverage |
| `iam:PassRole` error during setup | Attach the inline policy from the README to your IAM user |

## Cleanup

To remove all AWS resources and avoid charges:

```bash
API_ID=$(jq -r '.apiId' src/aws-config.json)
POLICY_ARN=$(jq -r '.policyArn' src/aws-config.json)

aws apigatewayv2 delete-api --api-id $API_ID
aws lambda delete-function --function-name onde-estou-geocode-reverse
aws lambda delete-function --function-name onde-estou-map-credentials
aws location delete-map --map-name onde-estou-map
aws location delete-place-index --index-name onde-estou-place-index
aws iam detach-role-policy --role-name onde-estou-lambda-role --policy-arn $POLICY_ARN
aws iam delete-policy --policy-arn $POLICY_ARN
aws iam delete-role --role-name onde-estou-lambda-role
```
