#!/bin/bash

# Multi-Region CI/CD Pipeline Deployment Script
# This script deploys the CI/CD pipeline with Dev in us-east-1 and Prod in us-west-1

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check required environment variables
if [ -z "$GITHUB_OWNER" ] || [ -z "$GITHUB_REPO" ] || [ -z "$GITHUB_TOKEN" ]; then
    print_error "Required environment variables are not set!"
    echo "Please set the following environment variables:"
    echo "  export GITHUB_OWNER=your-github-username"
    echo "  export GITHUB_REPO=your-repo-name"
    echo "  export GITHUB_TOKEN=your-github-token"
    exit 1
fi

# Set default region for pipeline (us-east-1)
export AWS_DEFAULT_REGION=us-east-1

print_message "Starting multi-region CI/CD pipeline deployment..."
print_message "Pipeline will be created in us-east-1"
print_message "Dev environment will deploy to us-east-1"
print_message "Prod environment will deploy to us-west-1"

# Step 1: Deploy IAM Roles (in us-east-1)
print_message "Step 1: Deploying IAM Roles..."
aws cloudformation deploy \
    --template-file infrastructure/iam-roles.yaml \
    --stack-name cicd-iam-roles \
    --capabilities CAPABILITY_NAMED_IAM \
    --region us-east-1

if [ $? -eq 0 ]; then
    print_message "IAM Roles deployed successfully!"
else
    print_error "Failed to deploy IAM Roles"
    exit 1
fi

# Step 2: Deploy CodeBuild Project (in us-east-1)
print_message "Step 2: Deploying CodeBuild Project..."
aws cloudformation deploy \
    --template-file infrastructure/codebuild-project.yaml \
    --stack-name cicd-codebuild \
    --capabilities CAPABILITY_IAM \
    --region us-east-1

if [ $? -eq 0 ]; then
    print_message "CodeBuild Project deployed successfully!"
else
    print_error "Failed to deploy CodeBuild Project"
    exit 1
fi

# Step 3: Create S3 bucket in us-west-1 first (required for multi-region pipeline)
print_message "Step 3: Creating artifact bucket in us-west-1..."
BUCKET_NAME_WEST="codepipeline-artifacts-$(aws sts get-caller-identity --query Account --output text)-us-west-1"

aws s3api create-bucket \
    --bucket $BUCKET_NAME_WEST \
    --region us-west-1 \
    --create-bucket-configuration LocationConstraint=us-west-1 2>/dev/null || print_warning "Bucket may already exist"

aws s3api put-bucket-versioning \
    --bucket $BUCKET_NAME_WEST \
    --versioning-configuration Status=Enabled \
    --region us-west-1

aws s3api put-public-access-block \
    --bucket $BUCKET_NAME_WEST \
    --public-access-block-configuration \
        "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
    --region us-west-1

print_message "Artifact bucket in us-west-1 created successfully!"

# Step 4: Deploy CodePipeline (in us-east-1 with multi-region support)
print_message "Step 4: Deploying CodePipeline with multi-region support..."
aws cloudformation deploy \
    --template-file infrastructure/codepipeline.yaml \
    --stack-name cicd-pipeline \
    --capabilities CAPABILITY_IAM \
    --parameter-overrides \
        GitHubOwner=$GITHUB_OWNER \
        GitHubRepo=$GITHUB_REPO \
        GitHubToken=$GITHUB_TOKEN \
        GitHubBranch=main \
    --region us-east-1

if [ $? -eq 0 ]; then
    print_message "CodePipeline deployed successfully!"
else
    print_error "Failed to deploy CodePipeline"
    exit 1
fi

# Summary
echo ""
print_message "=========================================="
print_message "Multi-Region CI/CD Pipeline Deployment Complete!"
print_message "=========================================="
echo ""
print_message "Pipeline Configuration:"
echo "  - Pipeline Region: us-east-1"
echo "  - Dev Environment: us-east-1"
echo "  - Prod Environment: us-west-1"
echo "  - Manual Approval: Required between Dev and Prod"
echo ""
print_message "Next Steps:"
echo "  1. Push code to your GitHub repository"
echo "  2. Pipeline will automatically deploy to Dev (us-east-1)"
echo "  3. Review Dev deployment and approve in CodePipeline console"
echo "  4. After approval, pipeline will deploy to Prod (us-west-1)"
echo ""
print_message "View your pipeline:"
echo "  https://console.aws.amazon.com/codesuite/codepipeline/pipelines/cicd-pipeline/view?region=us-east-1"
