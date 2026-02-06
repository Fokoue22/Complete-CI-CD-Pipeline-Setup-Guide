# START HERE - Complete Multi-Region CI/CD Pipeline

**Welcome!** This repository contains everything you need to deploy a production-ready, multi-region CI/CD pipeline on AWS.

## What You Get

This is a **complete, ready-to-use** CI/CD pipeline that:

 Automatically deploys to **Dev** (us-east-1) on every git push  
 Requires **manual approval** before production  
 Deploys to **Prod** (us-west-1) after approval  
 Uses **GitHub** for source control  
 Uses **AWS CodePipeline, CodeBuild, CloudFormation**  
 Includes **complete documentation**  
 Provides **automated deployment scripts**  

## Who Is This For?

- DevOps engineers setting up CI/CD pipelines
- Developers learning AWS deployment automation
- Teams needing multi-region deployment with approval gates
- Anyone wanting a production-ready pipeline template

## Quick Start (5 Minutes)

### Prerequisites

1. **AWS Account** with admin permissions
2. **AWS CLI** installed and configured
3. **GitHub Account** and repository
4. **Git** installed locally

### Step 1: Clone This Repository

```bash
git clone https://github.com/Fokoue22/Complete-CI-CD-Pipeline-Setup-Guide.git
cd Complete-CI-CD-Pipeline-Setup-Guide
```

### Step 2: Prepare Your GitHub Repository

1. **Create a new GitHub repository** or use an existing one
2. **Generate a Personal Access Token:**
   - Go to GitHub Settings → Developer settings → Personal access tokens → "Tokens (classic)"
   - Generate new token with `repo` permissions
       - Click "Generate new token (classic)"
       - Give it a descriptive name: AWS-CodePipeline-Token
       - Set expiration (recommend 30-90 days for security)
   - Select Required Scopes:
     - repo (Full control of private repositories)
       -  repo:status
       -  repo_deployment  
       -  public_repo
     -  admin:repo_hook (for webhook management)
       -  write:repo_hook
       -  read:repo_hook

   - Save the token securely (you'll need it later)
   - Security Best Practices: Store the token in a password manager
   #### Store securely in AWS Systems Manager Parameter Store
       aws ssm put-parameter \
        --name "/cicd/github-token" \
        --description "GitHub token for CodePipeline"
        --type "SecureString" \
        --value "ghp_your_token_here" \

3. **Clone your repository locally:**
   ```bash
   git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git
   cd YOUR_REPO
  
### Step 4: Add CI/CD Files to Your Repository

1. **Copy all the files from this ci-cd-pipline folder to your repository:**
   - `buildspec.yml`
   - `infrastructure/` folder with all CloudFormation templates
   - `src/` folder with sample application
   - `scripts/` folder with deployment scripts

2. **Commit and push your repo to GitHub:**
   ```bash
   git add .
   git commit -m "Add CI/CD pipeline configuration"
   git push origin main
   ```   ```    

### Step 5: Configure AWS CLI

1. **Install AWS CLI** (if not already installed):
   ```bash
   # Windows (using chocolatey)
   choco install awscli
   
   # Or download from AWS website
   ```

2. **Configure AWS CLI:**
   ```bash
   aws configure
   ```
   Enter your:
   - AWS Access Key ID
   - AWS Secret Access Key
   - Default region (e.g., us-east-1)
   - Default output format (json)

### Step 6: Deploy the CI/CD Infrastructure

#### Option A: Using the Deployment Script (Recommended)

1. **Set environment variables:**
   ```bash
   # Windows PowerShell
   $env:GITHUB_OWNER = "your-github-username"
   $env:GITHUB_REPO = "your-repo-name"
   $env:GITHUB_TOKEN = "your-github-personal-access-token"
   ```

2. **Run the deployment script:**
**Windows (PowerShell):**
```powershell
.\scripts\deploy-multi-region.ps1
```

**Linux/Mac/Git Bash:**
```bash
bash scripts/deploy-multi-region.sh
```   ```
   

####  Option B: Manual Deployment

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




### Step 7: Push Code to Trigger Pipeline

```bash
git add .
git commit -m "Initial deployment"
git push origin main
```

**That's it!** Your pipeline will automatically:
1. Build your code
2. Deploy to Dev (us-east-1)
3. Wait for your approval
4. Deploy to Prod (us-west-1)

## What Gets Deployed

### AWS Resources

| Resource | Region | Purpose |
|----------|--------|---------|
| IAM Roles | us-east-1 | Permissions for pipeline |
| CodeBuild Project | us-east-1 | Build and test |
| CodePipeline | us-east-1 | Orchestration |
| S3 Buckets | us-east-1, us-west-1 | Artifact storage |
| Dev Stack | us-east-1 | Development environment |
| Prod Stack | us-west-1 | Production environment |

### Pipeline Stages
![Alt text](images/Pipeline-view.png)


## Customization

### Change Regions

Edit `infrastructure/codepipeline.yaml`:

```yaml
# Change Dev region
- Name: DeployDev
  Actions:
    - Name: CreateChangeSetDev
      Region: eu-west-1  # Change this

# Change Prod region
- Name: DeployProd
  Actions:
    - Name: CreateChangeSetProd
      Region: ap-southeast-1  # Change this
```

### Add More Environments

1. Duplicate a Deploy stage in `codepipeline.yaml`
2. Change the stack name and region
3. Add another approval stage if needed

### Customize Build Process

Edit `buildspec.yml` to:
- Change runtime versions
- Add more tests
- Modify build commands
- Add deployment steps

### Modify Application Infrastructure

Edit `infrastructure/app-infrastructure.yaml` to deploy:
- Lambda functions
- API Gateway
- DynamoDB tables
- S3 buckets
- Any AWS resource

## Using Your Pipeline

### Trigger a Deployment

Just push to GitHub:
```bash
git add .
git commit -m "Your changes"
git push origin main
```

### Approve Production Deployment

**Option 1: AWS Console**
1. Go to https://console.aws.amazon.com/codesuite/codepipeline/
2. Click on `cicd-pipeline`
3. Click "Review" on Manual Approval
4. Click "Approve"

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

### Monitor Pipeline

```bash
# Check pipeline status
aws codepipeline get-pipeline-state \
  --name cicd-pipeline \
  --region us-east-1

# Check Dev deployment
aws cloudformation describe-stacks \
  --stack-name cicd-app-stack-dev \
  --region us-east-1

# Check Prod deployment
aws cloudformation describe-stacks \
  --stack-name cicd-app-stack-prod \
  --region us-west-1
```
### Multi-Region CI/CD Pipeline Deployment Guide
![Alt text](images/prod-stack.png)

## Cleanup

To remove everything:

```bash
# Delete application stacks
aws cloudformation delete-stack --stack-name cicd-app-stack-prod --region us-west-1
aws cloudformation delete-stack --stack-name cicd-app-stack-dev --region us-east-1

# Delete pipeline infrastructure
aws cloudformation delete-stack --stack-name cicd-pipeline --region us-east-1
aws cloudformation delete-stack --stack-name cicd-codebuild --region us-east-1
aws cloudformation delete-stack --stack-name cicd-iam-roles --region us-east-1

# Delete S3 buckets
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws s3 rb s3://codepipeline-artifacts-${ACCOUNT_ID}-us-east-1 --force
aws s3 rb s3://codepipeline-artifacts-${ACCOUNT_ID}-us-west-1 --force --region us-west-1
```

##  Cost Estimate

| Service | Estimated Cost |
|---------|----------------|
| CodePipeline | $1/month |
| CodeBuild | ~$0.005/build minute |
| S3 Storage | ~$0.023/GB/month |
| CloudFormation | Free |
| Data Transfer | ~$0.02/GB |

**Total:** $5-20/month depending on usage

##  Troubleshooting

### Pipeline Not Triggering

**Problem:** Push to GitHub doesn't trigger pipeline

**Solution:**
1. Check GitHub webhook in repository settings
2. Verify GitHub token has correct permissions
3. Ensure branch name is "main" (not "master")

### Build Failures

**Problem:** Build stage fails

**Solution:**
1. Check CodeBuild logs in CloudWatch
2. Verify `buildspec.yml` syntax
3. Check IAM permissions for CodeBuild role

### Deployment Failures

**Problem:** Deploy stage fails

**Solution:**
1. Check CloudFormation events for details
2. Verify template syntax in `app-infrastructure.yaml`
3. Check IAM permissions for CloudFormation role

### Approval Not Showing

**Problem:** Manual approval stage doesn't appear

**Solution:**
1. Verify Dev deployment completed successfully
2. Check pipeline execution status
3. Ensure you have approval permissions

## Learn More

### AWS Services Used

- **[AWS CodePipeline](https://aws.amazon.com/codepipeline/)** - CI/CD orchestration
- **[AWS CodeBuild](https://aws.amazon.com/codebuild/)** - Build and test
- **[AWS CloudFormation](https://aws.amazon.com/cloudformation/)** - Infrastructure as Code
- **[AWS IAM](https://aws.amazon.com/iam/)** - Permissions management
- **[Amazon S3](https://aws.amazon.com/s3/)** - Artifact storage

### Best Practices

Always test in Dev before approving Prod  
Review CloudFormation change sets before approval  
Add meaningful comments when approving  
Monitor both regions with CloudWatch  
Set up alarms for failures  
Regularly rotate GitHub tokens  
Use least privilege IAM permissions  
Enable CloudTrail for audit logging  

## Contributing

Found a bug or want to improve this? Contributions welcome!

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is provided as-is for educational and commercial use.


## Use Cases

This pipeline is perfect for:

- **Web Applications** - Deploy frontend/backend to multiple regions
- **APIs** - Deploy REST/GraphQL APIs with approval gates
- **Microservices** - Deploy containerized services
- **Static Websites** - Deploy to S3/CloudFront
- **Lambda Functions** - Deploy serverless applications
- **Infrastructure** - Deploy AWS resources via CloudFormation

## Security

- IAM roles use least privilege principle
- GitHub tokens stored securely in AWS
- S3 buckets have public access blocked
- CloudTrail enabled for audit logging
- Encryption at rest for artifacts
- VPC endpoints supported (optional)
 

**Made with ❤️ for the DevOps community**

**Repository:** https://github.com/Fokoue22/Complete-CI-CD-Pipeline-Setup-Guide

**Questions?** Open an issue on GitHub!
