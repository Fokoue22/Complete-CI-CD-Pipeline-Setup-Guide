# Multi-Region CI/CD Pipeline Deployment Script (PowerShell)
# This script deploys the CI/CD pipeline with Dev in us-east-1 and Prod in us-west-1

$ErrorActionPreference = "Stop"

# Function to print colored output
function Print-Message {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Print-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Print-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

# Check required environment variables
if (-not $env:GITHUB_OWNER -or -not $env:GITHUB_REPO -or -not $env:GITHUB_TOKEN) {
    Print-Error "Required environment variables are not set!"
    Write-Host "Please set the following environment variables:"
    Write-Host '  $env:GITHUB_OWNER = "your-github-username"'
    Write-Host '  $env:GITHUB_REPO = "your-repo-name"'
    Write-Host '  $env:GITHUB_TOKEN = "your-github-token"'
    exit 1
}

# Set default region for pipeline (us-east-1)
$env:AWS_DEFAULT_REGION = "us-east-1"

Print-Message "Starting multi-region CI/CD pipeline deployment..."
Print-Message "Pipeline will be created in us-east-1"
Print-Message "Dev environment will deploy to us-east-1"
Print-Message "Prod environment will deploy to us-west-1"

# Step 1: Deploy IAM Roles (in us-east-1)
Print-Message "Step 1: Deploying IAM Roles..."
aws cloudformation deploy `
    --template-file infrastructure/iam-roles.yaml `
    --stack-name cicd-iam-roles `
    --capabilities CAPABILITY_NAMED_IAM `
    --region us-east-1

if ($LASTEXITCODE -eq 0) {
    Print-Message "IAM Roles deployed successfully!"
} else {
    Print-Error "Failed to deploy IAM Roles"
    exit 1
}

# Step 2: Deploy CodeBuild Project (in us-east-1)
Print-Message "Step 2: Deploying CodeBuild Project..."
aws cloudformation deploy `
    --template-file infrastructure/codebuild-project.yaml `
    --stack-name cicd-codebuild `
    --capabilities CAPABILITY_IAM `
    --region us-east-1

if ($LASTEXITCODE -eq 0) {
    Print-Message "CodeBuild Project deployed successfully!"
} else {
    Print-Error "Failed to deploy CodeBuild Project"
    exit 1
}

# Step 3: Create S3 bucket in us-west-1 first (required for multi-region pipeline)
Print-Message "Step 3: Creating artifact bucket in us-west-1..."
$AccountId = aws sts get-caller-identity --query Account --output text
$BucketNameWest = "codepipeline-artifacts-$AccountId-us-west-1"

try {
    aws s3api create-bucket `
        --bucket $BucketNameWest `
        --region us-west-1 `
        --create-bucket-configuration LocationConstraint=us-west-1 2>$null
} catch {
    Print-Warning "Bucket may already exist"
}

aws s3api put-bucket-versioning `
    --bucket $BucketNameWest `
    --versioning-configuration Status=Enabled `
    --region us-west-1

aws s3api put-public-access-block `
    --bucket $BucketNameWest `
    --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" `
    --region us-west-1

Print-Message "Artifact bucket in us-west-1 created successfully!"

# Step 4: Deploy CodePipeline (in us-east-1 with multi-region support)
Print-Message "Step 4: Deploying CodePipeline with multi-region support..."
aws cloudformation deploy `
    --template-file infrastructure/codepipeline.yaml `
    --stack-name cicd-pipeline `
    --capabilities CAPABILITY_IAM `
    --parameter-overrides `
        GitHubOwner=$env:GITHUB_OWNER `
        GitHubRepo=$env:GITHUB_REPO `
        GitHubToken=$env:GITHUB_TOKEN `
        GitHubBranch=main `
    --region us-east-1

if ($LASTEXITCODE -eq 0) {
    Print-Message "CodePipeline deployed successfully!"
} else {
    Print-Error "Failed to deploy CodePipeline"
    exit 1
}

# Summary
Write-Host ""
Print-Message "=========================================="
Print-Message "Multi-Region CI/CD Pipeline Deployment Complete!"
Print-Message "=========================================="
Write-Host ""
Print-Message "Pipeline Configuration:"
Write-Host "  - Pipeline Region: us-east-1"
Write-Host "  - Dev Environment: us-east-1"
Write-Host "  - Prod Environment: us-west-1"
Write-Host "  - Manual Approval: Required between Dev and Prod"
Write-Host ""
Print-Message "Next Steps:"
Write-Host "  1. Push code to your GitHub repository"
Write-Host "  2. Pipeline will automatically deploy to Dev (us-east-1)"
Write-Host "  3. Review Dev deployment and approve in CodePipeline console"
Write-Host "  4. After approval, pipeline will deploy to Prod (us-west-1)"
Write-Host ""
Print-Message "View your pipeline:"
Write-Host "  https://console.aws.amazon.com/codesuite/codepipeline/pipelines/cicd-pipeline/view?region=us-east-1"
