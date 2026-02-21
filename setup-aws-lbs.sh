#!/bin/bash
# Full AWS Location Based Service setup for onde-estou
# Version: 0.10.0-alpha
# Runs infrastructure setup then deploys Lambda functions and API Gateway.
# Must be executed from the repository root.
#
# Usage:
#   ./setup-aws-lbs.sh
#   AWS_REGION=sa-east-1 ALLOWED_ORIGIN=http://localhost:3000 ./setup-aws-lbs.sh

set -e

# Resolve repo root regardless of where the script is called from
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "================================================"
echo "  onde-estou — AWS Location Based Service Setup"
echo "================================================"
echo ""

# Step 1: Create AWS resources (Map, Place Index, IAM role/policy)
echo ">>> Step 1/2: Setting up AWS infrastructure..."
echo ""
bash src/scripts/setup-aws-infrastructure.sh

echo ""
echo ">>> Step 2/2: Deploying Lambda functions and API Gateway..."
echo ""
bash src/scripts/deploy-backend.sh

echo ""
echo "================================================"
echo "  Setup complete!"
echo "================================================"
