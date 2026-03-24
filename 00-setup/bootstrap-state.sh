#!/usr/bin/env bash
# =============================================================================
# bootstrap-state.sh
# Run ONCE before `terraform init` to create the S3 backend.
# After this runs, fill in the bucket name in terraform/foundation/provider.tf
# =============================================================================
set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────────────────
AWS_REGION="${AWS_REGION:-ap-southeast-1}"
ENVIRONMENT="${ENVIRONMENT:-staging}" # staging/demo
PROJECT="nhi-demo"

# S3 bucket names must be globally unique — add identifier prefix and environment suffix
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="awodotsg-${PROJECT}-tfstate-${ENVIRONMENT}"

echo "=================================================="
echo " NHI Demo — Terraform State Bootstrap"
echo "=================================================="
echo " Account  : ${ACCOUNT_ID}"
echo " Region   : ${AWS_REGION}"
echo " Bucket   : ${BUCKET_NAME}"
echo "=================================================="
echo ""

# ── S3 Bucket ─────────────────────────────────────────────────────────────────
echo "[1/3] Creating S3 bucket..."

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

echo "[2/3] Enabling versioning (allows state rollback)..."
aws s3api put-bucket-versioning \
  --bucket "${BUCKET_NAME}" \
  --versioning-configuration Status=Enabled

echo "[3/3] Enabling server-side encryption (AES-256)..."
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
