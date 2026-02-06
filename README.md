# Complete Multi-Region CI/CD Pipeline

[![AWS](https://img.shields.io/badge/AWS-CodePipeline-orange)](https://aws.amazon.com/codepipeline/)
[![GitHub](https://img.shields.io/badge/GitHub-Integration-blue)](https://github.com)
[![CloudFormation](https://img.shields.io/badge/IaC-CloudFormation-green)](https://aws.amazon.com/cloudformation/)
[![Multi-Region](https://img.shields.io/badge/Deployment-Multi--Region-red)](https://aws.amazon.com/about-aws/global-infrastructure/)

> **Production-ready CI/CD pipeline with multi-region deployment and manual approval gates**

### New Here? [START HERE →](START_HERE.md)

### Architecture Review
![Alt text](images/3stage-architecture-cloudformation.png)

This is a **complete, ready-to-use** CI/CD pipeline featuring:
- **GitHub** for source control with webhook integration
- **AWS CodePipeline** for orchestration
- **AWS CodeBuild** for automated build/test
- **AWS CloudFormation** for Infrastructure as Code
- **Multi-Region Deployment** (Dev: us-east-1, Prod: us-west-1)
- **Manual Approval** gate before production
- **Complete Documentation** for every scenario
- **Automated Deployment Scripts** (PowerShell & Bash)

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
For basic setup with deployment to a single region, follow the [START_HERE.md](START_HERE.md)

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

See [START_HERE.md](START_HERE.md) for detailed instructions.

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
    └── START_HERE.md                      # Original single-region guide
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

See [START_HERE.md](START_HERE.md) for manual deployment steps.
