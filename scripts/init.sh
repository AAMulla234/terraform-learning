#!/bin/bash

# Check if all 5 required arguments are provided
if [ $# -ne 5 ]; then
  echo "Usage: $0 <project> <alias> <env> <slice> <region>"
  exit 1
fi

# Read command line arguments
project=$1
alias=$2
env=$3
slice=$4
region=$5

# Set S3 bucket naming convention
bucket="${project}-${alias}-${env}-${slice}-${region}"

# Set Terraform variable for lifecycle (used in .tf files)
if [[ "$env" == "prd" ]]; then
  export TF_VAR_account_lifecycle="live"
else
  export TF_VAR_account_lifecycle="development"
fi

# Optional: Export the bucket name to use in your Terraform configs as TF_VAR
export TF_VAR_tf_state_bucket=$bucket
export TF_VAR_region=$region

# Check if S3 bucket exists, create if not
if ! aws s3api head-bucket --bucket "$bucket" 2>/dev/null; then
  echo "Bucket $bucket does not exist. Creating..."
  aws s3api create-bucket \
    --bucket "$bucket" \
    --region "$region" \
    --create-bucket-configuration LocationConstraint="$region"

  # Optional: Enable versioning
  aws s3api put-bucket-versioning \
    --bucket "$bucket" \
    --versioning-configuration Status=Enabled

  # Optional: Enable encryption
  aws s3api put-bucket-encryption \
    --bucket "$bucket" \
    --server-side-encryption-configuration '{
      "Rules": [{
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        }
      }]
    }'

  echo "Bucket $bucket created and configured."
fi

# Initialize Terraform with dynamic backend configuration
terraform init \
  -backend-config="bucket=${bucket}" \
  -backend-config="key=contact-infrastructure.tfstate" \
  -backend-config="region=${region}" \
  -backend-config="encrypt=true"

# Display output info
echo
echo "****************************************************************"
echo "Terraform initialized for environment: $env"
echo "State bucket set to: ${bucket}"
echo "Region: ${region}"
echo "Account lifecycle: ${TF_VAR_account_lifecycle}"
echo "****************************************************************"
