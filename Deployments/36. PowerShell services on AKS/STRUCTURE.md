# 📁 Project Structure - PowerShell Services on AKS

This document describes the organization and purpose of all files in this deployment.

## 📂 Directory Structure

```
36. PowerShell services on AKS/
│
├── 📄 azuredeploy.json              # ARM template for AKS infrastructure
├── 📄 parameters.json               # Default parameters for deployment
├── 📄 README.md                     # Main documentation
├── 📄 DEPLOYMENT-GUIDE.md          # Step-by-step deployment instructions
├── 📄 STRUCTURE.md                 # This file - project structure documentation
│
├── 🌐 deploy-to-azure.html         # Web page with Deploy to Azure button
├── 🌐 azuredeploy.visualizer.html  # Architecture visualization page
│
└── 📁 PowerShellService/           # Sample PowerShell service
    ├── 📄 server.ps1               # PowerShell web service using Pode
    ├── 🐳 Dockerfile               # Container image definition
    ├── 📄 .dockerignore            # Files to exclude from Docker build
    ├── ⚙️ deployment.yaml          # Kubernetes deployment manifest
    ├── ⚙️ hpa.yaml                 # Horizontal Pod Autoscaler config
    ├── ⚙️ configmap.yaml           # Configuration map
    ├── 📄 build-and-push.ps1       # Script to build and push to ACR
    └── 📄 README.md                # Service-specific documentation
```

## 📄 File Descriptions

### Infrastructure Files

#### `azuredeploy.json`
**Purpose:** ARM template that deploys the complete AKS infrastructure

**Deploys:**
- Azure Kubernetes Service (AKS) cluster
- Azure Container Registry (ACR)
- Log Analytics Workspace
- System-assigned managed identity

**Key Features:**
- Developer-tier configuration (cost-optimized)
- Kubenet networking
- Container Insights enabled
- Defender for Containers enabled
- Auto-upgrade configured

**When to modify:**
- Changing node sizes or counts
- Updating Kubernetes version
- Enabling/disabling features
- Changing network configuration

#### `parameters.json`
**Purpose:** Parameter file with default values for deployment

**Contains:**
- Cluster name and DNS prefix
- Node configuration (count, size)
- Kubernetes version
- Container registry name
- Feature flags (auto-scaling, HTTP routing)
- Network plugin selection

**When to modify:**
- Before each deployment to set unique names
- To change default configurations
- To enable/disable optional features

### Documentation Files

#### `README.md`
**Purpose:** Main documentation and reference guide

**Sections:**
- Architecture overview
- Features and benefits
- Cost breakdown
- Deployment instructions
- Post-deployment setup
- Building and deploying containers
- Testing examples
- Monitoring and troubleshooting
- Security best practices

**Audience:** Anyone using or evaluating this solution

#### `DEPLOYMENT-GUIDE.md`
**Purpose:** Detailed step-by-step deployment walkthrough

**Sections:**
- Prerequisites checklist
- Phase-by-phase instructions
- Command examples for each step
- Validation steps
- Troubleshooting specific issues
- Cleanup procedures

**Audience:** Users deploying for the first time

#### `STRUCTURE.md` (This File)
**Purpose:** Explains the project organization and file purposes

**Audience:** Developers and contributors

### Web Interface Files

#### `deploy-to-azure.html`
**Purpose:** Interactive web page for Azure Portal deployment

**Features:**
- Deploy to Azure button
- Parameter descriptions
- Cost breakdown
- Post-deployment instructions
- Visual feature list
- Code examples

**When to use:**
- Quick deployment via Azure Portal
- Demonstrating the solution
- Sharing with non-technical users

#### `azuredeploy.visualizer.html`
**Purpose:** Visual architecture diagram and feature showcase

**Features:**
- Interactive architecture layers
- Component descriptions
- Cost breakdown visualization
- Feature grid
- Technology stack badges
- Use case examples

**When to use:**
- Understanding the architecture
- Presentations and demos
- Documentation and training

## 📦 PowerShell Service Files

### Application Files

#### `server.ps1`
**Purpose:** Main PowerShell web service using Pode framework

**Endpoints:**
- `/health` - Health check (liveness probe)
- `/ready` - Readiness check
- `/api/info` - Service and pod information
- `/api/routes` - List all available routes
- `/api/echo` - Echo request body
- `/api/process` - Data transformation
- `/api/azure/info` - Azure integration endpoint

**When to modify:**
- Adding new API endpoints
- Implementing business logic
- Changing service behavior
- Adding Azure integrations

### Container Files

#### `Dockerfile`
**Purpose:** Defines the container image

**Includes:**
- Base image: PowerShell 7.4 on Ubuntu 22.04
- Pode module installation
- Application files
- Exposure of port 8080
- Startup command

**When to modify:**
- Adding PowerShell modules
- Changing base image
- Adding system dependencies
- Modifying startup behavior

#### `.dockerignore`
**Purpose:** Excludes files from Docker build context

**Excludes:**
- YAML manifests
- Documentation files
- Git files
- Dockerfile itself

**When to modify:**
- Adding more files to exclude
- Optimizing build performance

### Kubernetes Manifests

#### `deployment.yaml`
**Purpose:** Kubernetes deployment and service definition

**Defines:**
- Deployment with 2 replicas
- Container configuration
- Resource requests and limits
- Health probes (liveness & readiness)
- LoadBalancer service

**When to modify:**
- Changing replica count
- Adjusting resource limits
- Updating image version
- Changing service type

#### `hpa.yaml`
**Purpose:** Horizontal Pod Autoscaler configuration

**Features:**
- Min: 2 replicas
- Max: 5 replicas
- CPU target: 70%
- Memory target: 80%
- Scale-up/down policies

**When to modify:**
- Adjusting scaling thresholds
- Changing min/max replicas
- Tuning scale-up/down behavior

#### `configmap.yaml`
**Purpose:** Configuration data for the application

**Contains:**
- Log level
- API version
- Environment settings
- Feature flags
- Custom settings

**When to modify:**
- Adding new configuration values
- Changing environment settings
- Enabling/disabling features

### Utility Scripts

#### `build-and-push.ps1`
**Purpose:** Automates building and pushing images to ACR

**Features:**
- Validates prerequisites (Azure CLI, Docker)
- Builds Docker image
- Logs into ACR
- Pushes image
- Verifies upload
- Provides next steps

**When to use:**
- Building and deploying new versions
- Automating CI/CD pipelines

**Parameters:**
- `-AcrName` (required): ACR name
- `-ImageName` (optional): Image name
- `-Tag` (optional): Image tag

#### `PowerShellService/README.md`
**Purpose:** Service-specific documentation

**Covers:**
- Quick start guide
- API endpoint reference
- Testing examples
- Configuration options
- Monitoring commands
- Scaling instructions

## 🔄 Typical Workflow

### Initial Deployment

1. **Deploy Infrastructure**
   - Use `azuredeploy.json` + `parameters.json`
   - Via Portal (`deploy-to-azure.html`) or CLI

2. **Configure Access**
   - Attach ACR to AKS
   - Get kubectl credentials

3. **Build and Deploy Service**
   - Build Docker image from `Dockerfile`
   - Push to ACR using `build-and-push.ps1`
   - Apply `deployment.yaml`

4. **Verify and Test**
   - Check pod status
   - Test endpoints
   - View logs and metrics

### Update Service

1. **Modify Code**
   - Edit `server.ps1`

2. **Rebuild and Push**
   - Build new image version
   - Push to ACR

3. **Update Deployment**
   - Update image tag in `deployment.yaml`
   - Apply changes
   - Monitor rollout

### Monitor and Scale

1. **View Metrics**
   - Use Azure Portal Insights
   - Query Log Analytics
   - Check `kubectl top`

2. **Scale as Needed**
   - Apply `hpa.yaml` for auto-scaling
   - Or manually scale deployment

## 📊 File Dependencies

```
azuredeploy.json
├── Creates: AKS Cluster
├── Creates: ACR
└── Creates: Log Analytics

deployment.yaml
├── Depends on: AKS Cluster (from azuredeploy.json)
├── Depends on: Container Image (from Dockerfile + build-and-push.ps1)
└── Creates: Pods and LoadBalancer Service

hpa.yaml
└── Depends on: deployment.yaml (powershell-service deployment)

configmap.yaml
└── Referenced by: deployment.yaml (optional)

build-and-push.ps1
├── Depends on: Dockerfile
├── Depends on: server.ps1
└── Pushes to: ACR (from azuredeploy.json)
```

## 🎯 Quick Reference

### For First-Time Users
1. Start with `README.md`
2. Follow `DEPLOYMENT-GUIDE.md`
3. Use `deploy-to-azure.html` for deployment

### For Developers
1. Review `STRUCTURE.md` (this file)
2. Modify `server.ps1` for custom logic
3. Use `build-and-push.ps1` for builds
4. Update `deployment.yaml` as needed

### For Architecture Review
1. Open `azuredeploy.visualizer.html`
2. Review `azuredeploy.json` for resources
3. Check `README.md` for features

### For Troubleshooting
1. Check `DEPLOYMENT-GUIDE.md` troubleshooting section
2. Review `README.md` monitoring section
3. Use commands in `PowerShellService/README.md`

## 🔑 Key Concepts

### Infrastructure as Code
- `azuredeploy.json` - Declarative infrastructure
- `parameters.json` - Configuration values
- Version controlled and repeatable

### Container Orchestration
- `Dockerfile` - Application packaging
- `deployment.yaml` - Desired state
- `hpa.yaml` - Auto-scaling rules

### Configuration Management
- `configmap.yaml` - Non-sensitive config
- Kubernetes secrets - Sensitive data (not included, create separately)
- Environment variables - Runtime config

## 📝 Notes

- All resource names must be globally unique (especially ACR and AKS DNS prefix)
- Developer tier is optimized for cost, not production workloads
- See security sections in README.md for production recommendations
- All PowerShell scripts use PowerShell 7.x syntax

---

**Last Updated:** December 2024


