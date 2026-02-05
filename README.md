# CI/CD Pipeline with GitHub, AWS CodeBuild, CodePipeline & CloudFormation

### Architecture Review
![Alt text](images/3stage-architecture-cloudformation.png)

This project demonstrates a complete CI/CD pipeline using:
- **GitHub** for source control
- **AWS CodePipeline** for orchestration
- **AWS CodeBuild** for build/test
- **AWS CloudFormation** for infrastructure deployment
- **Multi-Region Deployment** with manual approval

## Architecture Flow

1. Developer pushes code to GitHub
2. GitHub webhook triggers AWS CodePipeline
3. CodePipeline pulls source from GitHub
4. CodeBuild compiles, tests, and packages the application
5. CloudFormation deploys to Dev environment (us-east-1)
6. Manual approval required for production
7. CloudFormation deploys to Prod environment (us-west-1)

## Deployment Options

### Single Region Deployment
For basic setup with deployment to a single region, follow the [STEP_BY_STEP_GUIDE.md](STEP_BY_STEP_GUIDE.md)

### Multi-Region Deployment (Recommended)
For production-ready setup with Dev (us-east-1) and Prod (us-west-1) with manual approval, see [MULTI_REGION_DEPLOYMENT.md](MULTI_REGION_DEPLOYMENT.md)

## Quick Start

### Multi-Region Deployment (Dev → Approval → Prod)

```bash
# 1. Set environment variables
export GITHUB_OWNER="your-username"
export GITHUB_REPO="your-repo"
export GITHUB_TOKEN="your-token"

# 2. Deploy pipeline
bash scripts/deploy-multi-region.sh

# 3. Push code to trigger pipeline
git push origin main

# 4. Approve in AWS Console when ready for Prod
```

See [QUICK_START_MULTI_REGION.md](QUICK_START_MULTI_REGION.md) for detailed instructions.

## Prerequisites

- AWS CLI configured with appropriate permissions
- GitHub repository
- AWS account with necessary IAM permissions

## Setup Instructions

### 1. GitHub Setup
- Create a GitHub repository
- Generate a personal access token with repo permissions
- Store the token in AWS Systems Manager Parameter Store

### 2. AWS Setup
- Deploy the CloudFormation templates in order:
  1. `infrastructure/iam-roles.yaml` - IAM roles and policies
  2. `infrastructure/codebuild-project.yaml` - CodeBuild project
  3. `infrastructure/codepipeline.yaml` - CodePipeline setup

### 3. Application Deployment
- The pipeline will automatically deploy your application using the CloudFormation template in `infrastructure/app-infrastructure.yaml`

## Files Structure

```
Complete-CI-CD-Pipeline-Setup-Guide/
├── buildspec.yml                           # CodeBuild build specification
├── infrastructure/
│   ├── iam-roles.yaml                     # IAM roles (multi-region support)
│   ├── codebuild-project.yaml             # CodeBuild project setup
│   ├── codepipeline.yaml                  # Multi-region pipeline config
│   └── app-infrastructure.yaml            # Application infrastructure
├── src/                                   # Sample application code
├── scripts/
│   ├── deploy-multi-region.sh             # Bash deployment script
│   └── deploy-multi-region.ps1            # PowerShell deployment script
└── docs/
    ├── QUICK_START_MULTI_REGION.md        # Quick reference
    ├── MULTI_REGION_DEPLOYMENT.md         # Comprehensive guide
    ├── CHANGES_MULTI_REGION.md            # Change log
    ├── DEPLOYMENT_SUMMARY.md              # Summary overview
    └── STEP_BY_STEP_GUIDE.md              # Original single-region guide
```

## Deployment Commands

### Multi-Region Deployment (Recommended)

**Windows PowerShell:**
```powershell
$env:GITHUB_OWNER = "your-username"
$env:GITHUB_REPO = "your-repo"
$env:GITHUB_TOKEN = "your-token"
.\scripts\deploy-multi-region.ps1
```

**Linux/Mac/Git Bash:**
```bash
export GITHUB_OWNER="your-username"
export GITHUB_REPO="your-repo"
export GITHUB_TOKEN="your-token"
bash scripts/deploy-multi-region.sh
```

### Single Region Deployment (Legacy)

See [STEP_BY_STEP_GUIDE.md](STEP_BY_STEP_GUIDE.md) for manual deployment steps.

## Documentation Index

| Document | Description | When to Use |
|----------|-------------|-------------|
| [QUICK_REFERENCE.md](QUICK_REFERENCE.md) | Command cheat sheet | Quick lookups |
| [QUICK_START_MULTI_REGION.md](QUICK_START_MULTI_REGION.md) | Fast setup guide | First-time setup |
| [DEPLOYMENT_SUMMARY.md](DEPLOYMENT_SUMMARY.md) | Overview & checklist | Understanding the setup |
| [MULTI_REGION_DEPLOYMENT.md](MULTI_REGION_DEPLOYMENT.md) | Complete guide | Detailed information |
| [CHANGES_MULTI_REGION.md](CHANGES_MULTI_REGION.md) | Change log | Migration from old setup |
| [STEP_BY_STEP_GUIDE.md](STEP_BY_STEP_GUIDE.md) | Original guide | Single-region setup |