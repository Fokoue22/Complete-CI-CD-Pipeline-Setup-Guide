# Multi-Region CI/CD Pipeline Deployment Guide

## Overview

This guide explains how to deploy your application to multiple AWS regions with manual approval between environments:

- **Dev Environment**: us-east-1 (automatic deployment)
- **Manual Approval**: Required review step
- **Prod Environment**: us-west-1 (deployment after approval)

## Architecture

```
GitHub Push
    ↓
Source Stage (GitHub)
    ↓
Build Stage (CodeBuild in us-east-1)
    ↓
Deploy Dev (us-east-1)
    ↓
Manual Approval ⏸️
    ↓
Deploy Prod (us-west-1)
```

## Prerequisites

1. AWS CLI configured with appropriate permissions
2. GitHub repository with your code
3. GitHub Personal Access Token
4. Permissions to create resources in both us-east-1 and us-west-1

## Deployment Steps

### Option 1: Using PowerShell Script (Windows)

```powershell
# Set environment variables
$env:GITHUB_OWNER = "your-github-username"
$env:GITHUB_REPO = "your-repo-name"
$env:GITHUB_TOKEN = "your-github-token"

# Run deployment script
cd Complete-CI-CD-Pipeline-Setup-Guide
.\scripts\deploy-multi-region.ps1
```

### Option 2: Using Bash Script (Linux/Mac/Git Bash)

```bash
# Set environment variables
export GITHUB_OWNER="your-github-username"
export GITHUB_REPO="your-repo-name"
export GITHUB_TOKEN="your-github-token"

# Run deployment script
cd Complete-CI-CD-Pipeline-Setup-Guide
bash scripts/deploy-multi-region.sh
```

### Option 3: Manual Deployment

#### Step 1: Deploy IAM Roles (us-east-1)

```bash
aws cloudformation deploy \
  --template-file infrastructure/iam-roles.yaml \
  --stack-name cicd-iam-roles \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

#### Step 2: Deploy CodeBuild Project (us-east-1)

```bash
aws cloudformation deploy \
  --template-file infrastructure/codebuild-project.yaml \
  --stack-name cicd-codebuild \
  --capabilities CAPABILITY_IAM \
  --region us-east-1
```

#### Step 3: Create S3 Bucket in us-west-1

```bash
# Get your AWS Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Create bucket in us-west-1
aws s3api create-bucket \
  --bucket codepipeline-artifacts-${ACCOUNT_ID}-us-west-1 \
  --region us-west-1 \
  --create-bucket-configuration LocationConstraint=us-west-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket codepipeline-artifacts-${ACCOUNT_ID}-us-west-1 \
  --versioning-configuration Status=Enabled \
  --region us-west-1

# Block public access
aws s3api put-public-access-block \
  --bucket codepipeline-artifacts-${ACCOUNT_ID}-us-west-1 \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
  --region us-west-1
```

#### Step 4: Deploy CodePipeline (us-east-1)

```bash
aws cloudformation deploy \
  --template-file infrastructure/codepipeline.yaml \
  --stack-name cicd-pipeline \
  --capabilities CAPABILITY_IAM \
  --parameter-overrides \
    GitHubOwner=YOUR_GITHUB_USERNAME \
    GitHubRepo=YOUR_REPO_NAME \
    GitHubToken=YOUR_GITHUB_TOKEN \
    GitHubBranch=main \
  --region us-east-1
```

## Pipeline Workflow

### 1. Source Stage
- Triggered automatically when code is pushed to GitHub
- GitHub webhook notifies CodePipeline
- Source code is pulled into the pipeline

### 2. Build Stage
- CodeBuild compiles and tests your application
- Artifacts are created and stored in S3
- Build logs available in CloudWatch

### 3. Deploy Dev Stage (us-east-1)
- CloudFormation creates/updates the Dev stack
- Resources are deployed to us-east-1
- Stack name: `cicd-app-stack-dev`

### 4. Manual Approval Stage
- Pipeline pauses and waits for approval
- Email notification sent (if SNS configured)
- Reviewer can:
  - Approve: Continue to Prod deployment
  - Reject: Stop the pipeline
  - Add comments

### 5. Deploy Prod Stage (us-west-1)
- Only executes after manual approval
- CloudFormation creates/updates the Prod stack
- Resources are deployed to us-west-1
- Stack name: `cicd-app-stack-prod`

## Approving Deployments

### Via AWS Console

1. Go to CodePipeline console in us-east-1
2. Open the `cicd-pipeline` pipeline
3. Find the "ManualApproval" stage
4. Click "Review"
5. Add comments (optional)
6. Click "Approve" or "Reject"

### Via AWS CLI

```bash
# Get the approval token
aws codepipeline get-pipeline-state \
  --name cicd-pipeline \
  --region us-east-1

# Approve the deployment
aws codepipeline put-approval-result \
  --pipeline-name cicd-pipeline \
  --stage-name ManualApproval \
  --action-name ApprovalForProduction \
  --result status=Approved,summary="Approved for production deployment" \
  --token <TOKEN_FROM_GET_PIPELINE_STATE> \
  --region us-east-1
```

## Monitoring

### View Pipeline Status

```bash
# Get pipeline execution status
aws codepipeline get-pipeline-state \
  --name cicd-pipeline \
  --region us-east-1
```

### View Dev Stack (us-east-1)

```bash
aws cloudformation describe-stacks \
  --stack-name cicd-app-stack-dev \
  --region us-east-1
```

### View Prod Stack (us-west-1)

```bash
aws cloudformation describe-stacks \
  --stack-name cicd-app-stack-prod \
  --region us-west-1
```

### View Build Logs

```bash
# Get latest build ID
BUILD_ID=$(aws codebuild list-builds-for-project \
  --project-name cicd-build-project \
  --region us-east-1 \
  --query 'ids[0]' \
  --output text)

# Get build logs
aws codebuild batch-get-builds \
  --ids $BUILD_ID \
  --region us-east-1
```

## Testing Your Application

### Test Dev Environment (us-east-1)

```bash
# If deploying a Lambda function
aws lambda invoke \
  --function-name cicd-hello-world-dev \
  --region us-east-1 \
  response-dev.json

cat response-dev.json
```

### Test Prod Environment (us-west-1)

```bash
# If deploying a Lambda function
aws lambda invoke \
  --function-name cicd-hello-world-prod \
  --region us-west-1 \
  response-prod.json

cat response-prod.json
```

## Troubleshooting

### Pipeline Fails at Dev Deployment

1. Check CloudFormation events:
   ```bash
   aws cloudformation describe-stack-events \
     --stack-name cicd-app-stack-dev \
     --region us-east-1
   ```

2. Check IAM permissions for CloudFormation role
3. Verify template syntax in `app-infrastructure.yaml`

### Pipeline Fails at Prod Deployment

1. Check CloudFormation events:
   ```bash
   aws cloudformation describe-stack-events \
     --stack-name cicd-app-stack-prod \
     --region us-west-1
   ```

2. Ensure IAM roles have permissions in us-west-1
3. Verify S3 artifact bucket exists in us-west-1

### Manual Approval Not Showing

1. Check pipeline execution status
2. Verify Dev deployment completed successfully
3. Check IAM permissions for approval actions

### Build Failures

1. Check CodeBuild logs in CloudWatch
2. Verify `buildspec.yml` syntax
3. Check build environment configuration

## Customization

### Add Email Notifications for Approvals

1. Create an SNS topic:
   ```bash
   aws sns create-topic \
     --name cicd-approval-notifications \
     --region us-east-1
   ```

2. Subscribe your email:
   ```bash
   aws sns subscribe \
     --topic-arn arn:aws:sns:us-east-1:ACCOUNT_ID:cicd-approval-notifications \
     --protocol email \
     --notification-endpoint your-email@example.com \
     --region us-east-1
   ```

3. Update the Manual Approval stage in `codepipeline.yaml`:
   ```yaml
   - Name: ManualApproval
     Actions:
       - Name: ApprovalForProduction
         ActionTypeId:
           Category: Approval
           Owner: AWS
           Provider: Manual
           Version: '1'
         Configuration:
           NotificationArn: arn:aws:sns:us-east-1:ACCOUNT_ID:cicd-approval-notifications
           CustomData: 'Please review the Dev deployment and approve for Production'
   ```

### Add More Environments

To add a staging environment between Dev and Prod:

1. Add a new stage in `codepipeline.yaml` after DeployDev
2. Choose the target region (e.g., eu-west-1)
3. Create artifact bucket in that region
4. Update IAM roles to include the new region

### Change Deployment Regions

To deploy to different regions, update the `Region` parameter in the Deploy stages:

```yaml
- Name: DeployDev
  Actions:
    - Name: CreateChangeSetDev
      Region: eu-west-1  # Change to your desired region
```

## Cleanup

To remove all resources:

```bash
# Delete Prod stack (us-west-1)
aws cloudformation delete-stack \
  --stack-name cicd-app-stack-prod \
  --region us-west-1

# Delete Dev stack (us-east-1)
aws cloudformation delete-stack \
  --stack-name cicd-app-stack-dev \
  --region us-east-1

# Delete pipeline
aws cloudformation delete-stack \
  --stack-name cicd-pipeline \
  --region us-east-1

# Delete CodeBuild
aws cloudformation delete-stack \
  --stack-name cicd-codebuild \
  --region us-east-1

# Delete IAM roles
aws cloudformation delete-stack \
  --stack-name cicd-iam-roles \
  --region us-east-1

# Delete S3 buckets
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws s3 rb s3://codepipeline-artifacts-${ACCOUNT_ID}-us-east-1 --force
aws s3 rb s3://codepipeline-artifacts-${ACCOUNT_ID}-us-west-1 --force --region us-west-1
```

## Best Practices

1. **Always test in Dev first**: Never skip the Dev deployment
2. **Review changes carefully**: Check CloudFormation change sets before approval
3. **Use descriptive approval comments**: Document why you approved/rejected
4. **Monitor both regions**: Set up CloudWatch alarms in both us-east-1 and us-west-1
5. **Implement rollback strategy**: Have a plan to rollback Prod if issues occur
6. **Use parameter files**: Store environment-specific configurations separately
7. **Enable CloudTrail**: Track all API calls for audit purposes
8. **Rotate credentials**: Regularly update GitHub tokens and AWS credentials

## Security Considerations

1. **Least Privilege**: IAM roles should have minimal required permissions
2. **Encryption**: Enable encryption for S3 buckets and artifacts
3. **Secrets Management**: Use AWS Secrets Manager or Parameter Store for sensitive data
4. **Network Security**: Use VPC endpoints for AWS service communication
5. **Approval Controls**: Limit who can approve production deployments
6. **Audit Logging**: Enable CloudTrail in all regions

## Cost Optimization

- CodePipeline: $1/month per active pipeline
- CodeBuild: Pay per build minute
- S3 Storage: Pay for artifact storage in both regions
- CloudFormation: No additional charge
- Data Transfer: Cross-region data transfer charges apply

## Support

For issues or questions:
- Check AWS CodePipeline documentation
- Review CloudFormation stack events
- Check CloudWatch logs for detailed error messages
- Consult AWS Support if needed
