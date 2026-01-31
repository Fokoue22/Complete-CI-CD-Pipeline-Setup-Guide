# Complete CI/CD Pipeline Setup Guide

## 🎯 Overview
This guide will walk you through setting up a complete CI/CD pipeline using:
- **GitHub** (Source Control)
- **AWS CodePipeline** (Orchestration)
- **AWS CodeBuild** (Build/Test)
- **AWS CloudFormation** (Infrastructure as Code)

## 📋 Prerequisites

### 1. AWS Account Setup
- AWS account with administrative permissions
- AWS CLI installed and configured
- Sufficient permissions for IAM, S3, CodePipeline, CodeBuild, CloudFormation

### 2. GitHub Setup
- GitHub account
- Repository for your project
- Personal Access Token with repo permissions

### 3. Local Environment
- AWS CLI installed
- Git installed
- Text editor or IDE

## 🚀 Step-by-Step Implementation

### Step 1: Prepare Your GitHub Repository

1. **Create a new GitHub repository** or use an existing one
2. **Generate a Personal Access Token:**
   - Go to GitHub Settings → Developer settings → Personal access tokens → "Tokens (classic)"
   - Generate new token with `repo` permissions
       - Click "Generate new token (classic)"
       - Give it a descriptive name: AWS-CodePipeline-Token
       - Set expiration (recommend 30-90 days for security)
   - Select Required Scopes:
     - ✅ repo (Full control of private repositories)
       - ✅ repo:status
       - ✅ repo_deployment  
       - ✅ public_repo
     - ✅ admin:repo_hook (for webhook management)
       - ✅ write:repo_hook
       - ✅ read:repo_hook

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
   ```

### Step 2: Add CI/CD Files to Your Repository

1. **Copy all the files from this ci-cd-pipline folder to your repository:**
   - `buildspec.yml`
   - `infrastructure/` folder with all CloudFormation templates
   - `src/` folder with sample application
   - `scripts/` folder with deployment scripts

2. **Commit and push to GitHub:**
   ```bash
   git add .
   git commit -m "Add CI/CD pipeline configuration"
   git push origin main
   ```

### Step 3: Configure AWS CLI

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

### Step 4: Deploy the CI/CD Infrastructure

#### Option A: Using the Deployment Script (Recommended)

1. **Set environment variables:**
   ```bash
   # Windows PowerShell
   $env:GITHUB_OWNER = "your-github-username"
   $env:GITHUB_REPO = "your-repo-name"
   $env:GITHUB_TOKEN = "your-github-personal-access-token"
   $env:AWS_DEFAULT_REGION = "us-east-1"
   ```

2. **Run the deployment script:**
   ```bash
   # If on Windows with Git Bash or WSL
   bash scripts/deploy.sh
   
   # Or run commands manually (see Option B)
   ```

#### Option B: Manual Deployment

1. **Deploy IAM Roles:**
   ```bash
   aws cloudformation deploy \
     --template-file infrastructure/iam-roles.yaml \
     --stack-name cicd-iam-roles \
     --capabilities CAPABILITY_NAMED_IAM \
     --region us-east-1
   ```

2. **Deploy CodeBuild Project:**
   ```bash
   aws cloudformation deploy \
     --template-file infrastructure/codebuild-project.yaml \
     --stack-name cicd-codebuild \
     --capabilities CAPABILITY_IAM \
     --region us-east-1
   ```

3. **Deploy CodePipeline:**
   ```bash
   aws cloudformation deploy \
     --template-file infrastructure/codepipeline.yaml \
     --stack-name cicd-pipeline \
     --capabilities CAPABILITY_IAM \
     --parameter-overrides \
       GitHubOwner=YOUR_GITHUB_USERNAME \
       GitHubRepo=YOUR_REPO_NAME \
       GitHubToken=YOUR_GITHUB_TOKEN \
     --region us-east-1
   ```

### Step 5: Verify the Pipeline

1. **Check AWS Console:**
   - Go to AWS CodePipeline console
   - Find your pipeline named "cicd-pipeline"
   - Verify all stages are created

2. **Test the Pipeline:**
   - Make a small change to your code
   - Push to GitHub
   - Watch the pipeline automatically trigger

### Step 6: Monitor and Troubleshoot

1. **Pipeline Monitoring:**
   - AWS CodePipeline console shows execution status
   - CodeBuild logs available in CloudWatch
   - CloudFormation events show deployment progress

2. **Common Issues:**
   - **GitHub webhook not working:** Check GitHub token permissions
   - **Build failures:** Check buildspec.yml and CodeBuild logs
   - **Deployment failures:** Check CloudFormation events and IAM permissions

## 🔧 Customization Options

### Modify the Build Process
Edit `buildspec.yml` to customize:
- Runtime versions
- Build commands
- Test commands
- Artifact generation

### Add More Environments
1. Duplicate the Deploy stage in `codepipeline.yaml`
2. Add environment-specific parameters
3. Create separate CloudFormation templates for each environment

### Add Approval Gates
Add manual approval actions between stages:
```yaml
- Name: Approval
  Actions:
    - Name: ManualApproval
      ActionTypeId:
        Category: Approval
        Owner: AWS
        Provider: Manual
        Version: '1'
```

## 🧹 Cleanup

To remove all resources:

1. **Using the cleanup script:**
   ```bash
   bash scripts/cleanup.sh
   ```

2. **Manual cleanup:**
   ```bash
   # Delete stacks in reverse order
   aws cloudformation delete-stack --stack-name cicd-app-stack
   aws cloudformation delete-stack --stack-name cicd-pipeline
   aws cloudformation delete-stack --stack-name cicd-codebuild
   aws cloudformation delete-stack --stack-name cicd-iam-roles
   ```

## 📚 Additional Resources

- [AWS CodePipeline Documentation](https://docs.aws.amazon.com/codepipeline/)
- [AWS CodeBuild Documentation](https://docs.aws.amazon.com/codebuild/)
- [AWS CloudFormation Documentation](https://docs.aws.amazon.com/cloudformation/)
- [GitHub Webhooks Documentation](https://docs.github.com/en/developers/webhooks-and-events/webhooks)

## 🎉 Success Indicators

Your pipeline is working correctly when:
- ✅ All CloudFormation stacks deploy successfully
- ✅ CodePipeline shows all stages as "Succeeded"
- ✅ GitHub pushes automatically trigger the pipeline
- ✅ Your application is deployed and accessible
- ✅ Build logs show successful compilation and tests

## 🔐 Security Best Practices

1. **Use IAM roles with minimal permissions**
2. **Store secrets in AWS Systems Manager Parameter Store**
3. **Enable CloudTrail for audit logging**
4. **Use S3 bucket policies to restrict access**
5. **Regularly rotate GitHub tokens**