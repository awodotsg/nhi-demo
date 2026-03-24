#!/usr/bin/env bash
# =============================================================================
# bootstrap-state.sh
# Run ONCE before `terraform init` to create the S3 + DynamoDB backend.
# After this runs, fill in the bucket name in terraform/foundation/provider.tf
# =============================================================================
set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────────────────
AWS_REGION="${AWS_REGION:-ap-southeast-1}"
ENVIRONMENT="${ENVIRONMENT:-staging}" # staging/demo
PROJECT="nhi-demo"

# S3 bucket names must be globally unique — we suffix with the account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="${PROJECT}-tfstate-${ACCOUNT_ID}"
DYNAMO_TABLE="${PROJECT}-tfstate-lock"

echo "=================================================="
echo " NHI Demo — Terraform State Bootstrap"
echo "=================================================="
echo " Account  : ${ACCOUNT_ID}"
echo " Region   : ${AWS_REGION}"
echo " Bucket   : ${BUCKET_NAME}"
echo " DynamoDB : ${DYNAMO_TABLE}"
echo "=================================================="
echo ""

# ── S3 Bucket ─────────────────────────────────────────────────────────────────
echo "[1/4] Creating S3 bucket..."

# us-east-1 does not accept a LocationConstraint — every other region does
if [ "${AWS_REGION}" = "us-east-1" ]; then
  aws s3api create-bucket \
    --bucket "${BUCKET_NAME}" \
    --region "${AWS_REGION}" 2>/dev/null || echo "  Bucket already exists, continuing..."
else
  aws s3api create-bucket \
    --bucket "${BUCKET_NAME}" \
    --region "${AWS_REGION}" \
    --create-bucket-configuration LocationConstraint="${AWS_REGION}" 2>/dev/null || echo "  Bucket already exists, continuing..."
fi

echo "[2/4] Enabling versioning (allows state rollback)..."
aws s3api put-bucket-versioning \
  --bucket "${BUCKET_NAME}" \
  --versioning-configuration Status=Enabled

echo "[3/4] Enabling server-side encryption (AES-256)..."
aws s3api put-bucket-encryption \
  --bucket "${BUCKET_NAME}" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

echo "      Blocking all public access..."
aws s3api put-public-access-block \
  --bucket "${BUCKET_NAME}" \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# ── DynamoDB Table ─────────────────────────────────────────────────────────────
echo "[4/4] Creating DynamoDB lock table..."
aws dynamodb create-table \
  --table-name "${DYNAMO_TABLE}" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "${AWS_REGION}" \
  --tags Key=Project,Value="${PROJECT}" Key=ManagedBy,Value=bootstrap \
  --no-cli-pager \
  2>/dev/null || echo "  Table already exists, continuing..."

echo ""
echo "=================================================="
echo " ✅ Bootstrap complete!"
echo "=================================================="
echo ""
echo " Next step: update terraform/foundation/provider.tf"
echo " Set the backend bucket to: ${BUCKET_NAME}"
echo " Set the region to:         ${AWS_REGION}"
echo ""
echo " Then run:"
echo "   cd terraform/foundation"
echo "   terraform init"
echo "=================================================="
