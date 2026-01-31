#!/bin/bash

# CI/CD Pipeline Deployment Script
# This script deploys the entire CI/CD pipeline infrastructure

set -e

echo "🚀 Starting CI/CD Pipeline Deployment..."

# Configuration
STACK_PREFIX="cicd"
REGION=${AWS_DEFAULT_REGION:-us-east-1}
GITHUB_OWNER=${GITHUB_OWNER:-"your-github-username"}
GITHUB_REPO=${GITHUB_REPO:-"your-repo-name"}
GITHUB_TOKEN=${GITHUB_TOKEN:-"your-github-token"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    echo "🔍 Checking prerequisites..."
    
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed"
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS CLI is not configured or credentials are invalid"
        exit 1
    fi
    
    print_status "Prerequisites check passed"
}

# Deploy IAM roles
deploy_iam_roles() {
    echo "📋 Deploying IAM roles..."
    
    aws cloudformation deploy \
        --template-file infrastructure/iam-roles.yaml \
        --stack-name ${STACK_PREFIX}-iam-roles \
        --capabilities CAPABILITY_NAMED_IAM \
        --region $REGION
    
    print_status "IAM roles deployed successfully"
}

# Deploy CodeBuild project
deploy_codebuild() {
    echo "🔨 Deploying CodeBuild project..."
    
    aws cloudformation deploy \
        --template-file infrastructure/codebuild-project.yaml \
        --stack-name ${STACK_PREFIX}-codebuild \
        --capabilities CAPABILITY_IAM \
        --region $REGION
    
    print_status "CodeBuild project deployed successfully"
}

# Deploy CodePipeline
deploy_codepipeline() {
    echo "🔄 Deploying CodePipeline..."
    
    if [ "$GITHUB_TOKEN" = "your-github-token" ]; then
        print_error "Please set your GitHub token in the GITHUB_TOKEN environment variable"
        exit 1
    fi
    
    aws cloudformation deploy \
        --template-file infrastructure/codepipeline.yaml \
        --stack-name ${STACK_PREFIX}-pipeline \
        --capabilities CAPABILITY_IAM \
        --parameter-overrides \
            GitHubOwner=$GITHUB_OWNER \
            GitHubRepo=$GITHUB_REPO \
            GitHubToken=$GITHUB_TOKEN \
        --region $REGION
    
    print_status "CodePipeline deployed successfully"
}

# Get outputs
get_outputs() {
    echo "📊 Getting deployment outputs..."
    
    PIPELINE_NAME=$(aws cloudformation describe-stacks \
        --stack-name ${STACK_PREFIX}-pipeline \
        --query 'Stacks[0].Outputs[?OutputKey==`CodePipelineName`].OutputValue' \
        --output text \
        --region $REGION)
    
    echo "Pipeline Name: $PIPELINE_NAME"
    echo "AWS Console: https://${REGION}.console.aws.amazon.com/codesuite/codepipeline/pipelines/${PIPELINE_NAME}/view"
}

# Main deployment function
main() {
    echo "🎯 Deploying CI/CD Pipeline Infrastructure"
    echo "Region: $REGION"
    echo "GitHub Owner: $GITHUB_OWNER"
    echo "GitHub Repo: $GITHUB_REPO"
    echo ""
    
    check_prerequisites
    deploy_iam_roles
    deploy_codebuild
    deploy_codepipeline
    get_outputs
    
    print_status "🎉 CI/CD Pipeline deployment completed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Push your code to GitHub repository"
    echo "2. The pipeline will automatically trigger and deploy your application"
    echo "3. Monitor the pipeline in AWS Console"
}

# Run main function
main "$@"