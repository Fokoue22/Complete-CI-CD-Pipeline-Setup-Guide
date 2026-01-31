#!/bin/bash

# CI/CD Pipeline Cleanup Script
# This script removes all CI/CD pipeline infrastructure

set -e

echo "🧹 Starting CI/CD Pipeline Cleanup..."

# Configuration
STACK_PREFIX="cicd"
REGION=${AWS_DEFAULT_REGION:-us-east-1}

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

# Delete stack function
delete_stack() {
    local stack_name=$1
    echo "🗑️  Deleting stack: $stack_name"
    
    if aws cloudformation describe-stacks --stack-name $stack_name --region $REGION &> /dev/null; then
        aws cloudformation delete-stack --stack-name $stack_name --region $REGION
        
        echo "⏳ Waiting for stack deletion to complete..."
        aws cloudformation wait stack-delete-complete --stack-name $stack_name --region $REGION
        
        print_status "Stack $stack_name deleted successfully"
    else
        print_warning "Stack $stack_name does not exist"
    fi
}

# Empty S3 buckets before deletion
empty_s3_buckets() {
    echo "🪣 Emptying S3 buckets..."
    
    # Get bucket names from CloudFormation outputs
    local buckets=(
        "codepipeline-artifacts-$(aws sts get-caller-identity --query Account --output text)-$REGION"
        "codebuild-artifacts-$(aws sts get-caller-identity --query Account --output text)-$REGION"
    )
    
    for bucket in "${buckets[@]}"; do
        if aws s3 ls "s3://$bucket" &> /dev/null; then
            echo "Emptying bucket: $bucket"
            aws s3 rm "s3://$bucket" --recursive
            print_status "Bucket $bucket emptied"
        else
            print_warning "Bucket $bucket does not exist"
        fi
    done
}

# Main cleanup function
main() {
    echo "🎯 Cleaning up CI/CD Pipeline Infrastructure"
    echo "Region: $REGION"
    echo ""
    
    print_warning "This will delete all CI/CD pipeline resources!"
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cleanup cancelled"
        exit 0
    fi
    
    # Delete application stack first
    delete_stack "${STACK_PREFIX}-app-stack"
    
    # Empty S3 buckets
    empty_s3_buckets
    
    # Delete pipeline stack
    delete_stack "${STACK_PREFIX}-pipeline"
    
    # Delete CodeBuild stack
    delete_stack "${STACK_PREFIX}-codebuild"
    
    # Delete IAM roles stack (last)
    delete_stack "${STACK_PREFIX}-iam-roles"
    
    print_status "🎉 CI/CD Pipeline cleanup completed successfully!"
}

# Run main function
main "$@"