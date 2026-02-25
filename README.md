# GitOps Kubernetes on GCP with Terraform, Ansible & Argo CD

A complete, production-ready implementation of a GitOps-driven Kubernetes cluster on Google Cloud Platform with automated infrastructure provisioning, configuration management, and continuous deployment.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Infrastructure Setup](#infrastructure-setup)
- [Application Deployment](#application-deployment)
- [CI/CD Pipeline](#cicd-pipeline)
- [Monitoring and Management](#monitoring-and-management)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## Overview

This project demonstrates hands-on expertise in:

- **Infrastructure as Code (IaC)**: Terraform for provisioning GCP resources (GKE, VPC, Compute Engine)
- **Configuration Management**: Ansible for cluster setup and node configuration
- **Container Orchestration**: Kubernetes with advanced deployment strategies
- **GitOps**: Argo CD for continuous delivery from Git repository
- **Service Mesh**: Linkerd for traffic management and observability
- **CI/CD**: GitHub Actions for automated build, test, and deployment
- **Cloud Platform**: Google Cloud Platform (GCP) with GKE, VPC, and Cloud Storage

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     GitHub Repository                       │
│  ├─ terraform/        (Infrastructure as Code)              │
│  ├─ ansible/          (Configuration Management)            │
│  ├─ backend/          (Node.js API)                         │
│  ├─ frontend/         (React App)                           │
│  ├─ kubernetes/       (K8s Manifests)                       │
│  ├─ argocd/           (Argo CD Configuration)               │
│  └─ .github/workflows (CI/CD Pipelines)                     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────┐
        │      GitHub Actions CI/CD            │
        │  ├─ Build Docker Images              │
        │  ├─ Push to GCR                      │
        │  └─ Provision Infrastructure         │
        └─────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────┐
        │    Google Cloud Platform (GCP)       │
        │  ├─ VPC Network                      │
        │  ├─ GKE Cluster                      │
        │  ├─ Container Registry (GCR)         │
        │  └─ Cloud Storage                    │
        └─────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────┐
        │     Kubernetes Cluster               │
        │  ├─ Argo CD (Continuous Delivery)    │
        │  ├─ Linkerd (Service Mesh)           │
        │  ├─ Backend Service (3 replicas)     │
        │  └─ Frontend Service (3 replicas)    │
        └─────────────────────────────────────┘
```

## Prerequisites

- **GCP Account**: With billing enabled
- **Google Cloud SDK**: `gcloud` CLI installed and configured
- **Terraform**: v1.0 or later
- **Ansible**: v2.10 or later
- **kubectl**: Kubernetes CLI
- **Docker**: For building and testing images locally
- **GitHub Account**: With repository access and personal access token
- **Text Editor/IDE**: VS Code recommended

### Installation

```bash
# Install Google Cloud SDK
curl https://sdk.cloud.google.com | bash

# Install Terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform

# Install Ansible
pip install ansible==7.0.0
pip install kubernetes==27.2.0
pip install google-auth==2.20.0

# Install kubectl
gcloud components install kubectl
```

## Quick Start

### 1. Clone and Setup

```bash
git clone https://github.com/your-username/gitops-k8s-gcp.git
cd gitops-k8s-gcp

# Create terraform variables file
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
```

### 2. Configure GCP

```bash
# Set your GCP project
export GCP_PROJECT_ID="your-project-id"
gcloud config set project $GCP_PROJECT_ID

# Create a GCP service account for Terraform
gcloud iam service-accounts create terraform-sa \
  --display-name="Terraform Service Account"

# Grant necessary permissions
gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
  --member="serviceAccount:terraform-sa@${GCP_PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/compute.admin"

gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
  --member="serviceAccount:terraform-sa@${GCP_PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/container.admin"

# Create and download service account key
gcloud iam service-accounts keys create terraform-key.json \
  --iam-account=terraform-sa@${GCP_PROJECT_ID}.iam.gserviceaccount.com

export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/terraform-key.json"
```

### 3. Update Configuration

Edit `terraform/terraform.tfvars`:

```hcl
project_id           = "your-gcp-project-id"
region               = "us-central1"
cluster_name         = "gitops-cluster"
environment          = "production"
node_count           = 3
machine_type         = "n1-standard-2"
use_preemptible_nodes = false
```

### 4. Provision Infrastructure

```bash
cd terraform

# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Apply configuration
terraform apply

# Save outputs
terraform output > ../gke-cluster-info.txt
```

### 5. Configure Cluster Access

```bash
# Get cluster credentials
gcloud container clusters get-credentials gitops-cluster \
  --region us-central1 \
  --project $GCP_PROJECT_ID

# Verify cluster access
kubectl get nodes
```

### 6. Setup Argo CD and Linkerd

```bash
cd ../ansible

# Update inventory
# Edit inventory.ini with your cluster details

# Run setup playbook
ansible-playbook -i inventory.ini setup-cluster.yml \
  -e "gcp_project_id=$GCP_PROJECT_ID"
```

### 7. Configure Argo CD

```bash
# Get Argo CD admin password
kubectl get secret -n argocd argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d

# Port forward to access UI
kubectl port-forward -n argocd svc/argocd-server 8080:443

# Access: https://localhost:8080 (username: admin)
```

### 8. Deploy Application via Argo CD

Update `argocd/github-credentials.yaml` with your GitHub credentials, then:

```bash
# Create GitHub credentials secret
kubectl apply -f argocd/github-credentials.yaml

# Create Argo CD application
kubectl apply -f argocd/gitops-app.yaml
```

## Project Structure

```
gitops-k8s-gcp/
├── terraform/                 # Infrastructure as Code
│   ├── main.tf               # Main Terraform configuration
│   ├── variables.tf          # Variable definitions
│   ├── outputs.tf            # Output definitions
│   └── terraform.tfvars.example
│
├── ansible/                   # Configuration Management
│   ├── setup-cluster.yml     # Cluster setup playbook
│   ├── inventory.ini         # Ansible inventory
│   └── ansible.cfg           # Ansible configuration
│
├── backend/                   # Backend API (Node.js)
│   ├── server.js             # Express API server
│   ├── package.json          # Dependencies
│   ├── Dockerfile            # Container image
│   └── .dockerignore         # Docker ignore file
│
├── frontend/                  # Frontend App (React)
│   ├── App.js                # Main React component
│   ├── App.css               # Styling
│   ├── index.js              # Entry point
│   ├── package.json          # Dependencies
│   ├── Dockerfile            # Container image
│   ├── public/               # Static files
│   └── .env.example          # Environment variables
│
├── kubernetes/                # Kubernetes Manifests
│   ├── namespace.yaml        # Namespace configuration
│   ├── backend-deployment.yaml
│   ├── backend-service.yaml
│   ├── backend-hpa.yaml      # Horizontal Pod Autoscaler
│   ├── frontend-deployment.yaml
│   ├── frontend-service.yaml
│   ├── frontend-hpa.yaml
│   └── ingress.yaml          # Ingress configuration
│
├── argocd/                    # Argo CD Configuration
│   ├── gitops-app.yaml       # Argo CD Application
│   ├── argocd-config.yaml    # Argo CD ConfigMap
│   ├── github-credentials.yaml
│   └── app-project.yaml      # Argo CD AppProject
│
├── .github/
│   └── workflows/            # GitHub Actions CI/CD
│       ├── backend.yml       # Backend build and push
│       ├── frontend.yml      # Frontend build and push
│       └── terraform.yml     # Infrastructure automation
│
└── README.md                 # This file
```

## Infrastructure Setup

### Terraform Overview

The Terraform configuration provisions:

1. **VPC Network**: Custom VPC with subnets and secondary IP ranges
2. **GKE Cluster**: Managed Kubernetes cluster with:
   - Network policies enabled
   - Workload Identity for secure pod authentication
   - Auto-scaling node pools
   - Addon services (HTTP load balancing, HPA)

3. **Node Pools**: Auto-scaling compute instances
4. **Service Account**: For pod authentication and GCP API access
5. **Cloud Storage**: For artifact storage

### Running Terraform

```bash
cd terraform

# Initialize with remote backend (optional)
terraform init -backend-config="bucket=your-tf-state-bucket"

# Format code
terraform fmt -recursive

# Validate
terraform validate

# Plan and apply
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars

# Destroy (when done)
terraform destroy -var-file=terraform.tfvars
```

## Application Deployment

### Backend API

The backend is a Node.js/Express server with:

- RESTful endpoints for user management
- Health check endpoints (`/health`, `/readiness`)
- CORS support
- Graceful error handling
- Docker containerization

**Endpoints**:
- `GET /health` - Health check
- `GET /readiness` - Readiness probe
- `GET /api/v1/info` - Service information
- `GET /api/v1/users` - List all users
- `GET /api/v1/users/:id` - Get user by ID
- `POST /api/v1/users` - Create new user

**Deployment**:
```bash
cd backend

# Install dependencies
npm install

# Run locally
npm start

# Build Docker image
docker build -t backend:latest .

# Push to GCR
docker tag backend:latest gcr.io/your-project/backend:latest
docker push gcr.io/your-project/backend:latest
```

### Frontend Application

The frontend is a React application with:

- User management interface
- API integration
- Responsive design
- Tech stack showcase
- Environment-based configuration

**Configuration**:
- Set `REACT_APP_API_URL` to point to backend
- Default: `http://localhost:3000` (dev) or `http://backend-api.gitops-app.svc.cluster.local` (production)

**Deployment**:
```bash
cd frontend

# Install dependencies
npm install

# Run locally
npm start

# Build and containerize
npm run build
docker build -t frontend:latest .

# Push to GCR
docker tag frontend:latest gcr.io/your-project/frontend:latest
docker push gcr.io/your-project/frontend:latest
```

## CI/CD Pipeline

### GitHub Actions Workflows

#### Backend Pipeline (`backend.yml`)
1. Trigger on push/PR to `main` branch (backend path changes)
2. Authenticate to GCP using Workload Identity
3. Build Docker image
4. Push to Google Container Registry
5. Update deployment manifest with new image
6. Commit and push changes (triggers Argo CD)

#### Frontend Pipeline (`frontend.yml`)
1. Same flow as backend
2. Builds React frontend
3. Pushes optimized multi-stage image
4. Updates deployment manifest

#### Terraform Pipeline (`terraform.yml`)
1. Trigger on push/PR (terraform path changes)
2. Validate Terraform configuration
3. Plan infrastructure changes
4. Comment plan on PR
5. Auto-apply on merge to main

### GitHub Secrets Required

```
WIP                  # Workload Identity Provider (GCP)
SERVICE_ACCOUNT      # GCP Service Account email
GCP_PROJECT_ID       # GCP Project ID
```

### Setting Up Workload Identity Federation

```bash
# Create Workload Identity Pool
gcloud iam workload-identity-pools create "github-pool" \
  --project="${GCP_PROJECT_ID}" \
  --location="global" \
  --display-name="GitHub Actions"

# Create Workload Identity Provider
gcloud iam workload-identity-pools providers create-oidc "github-provider" \
  --project="${GCP_PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool="github-pool" \
  --display-name="GitHub" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.aud=assertion.aud,attribute.repository=assertion.repository" \
  --issuer-uri="https://token.actions.githubusercontent.com"

# Create service account
gcloud iam service-accounts create github-actions \
  --project="${GCP_PROJECT_ID}" \
  --display-name="GitHub Actions Service Account"

# Grant permissions
gcloud projects add-iam-policy-binding "${GCP_PROJECT_ID}" \
  --member="serviceAccount:github-actions@${GCP_PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/container.developer"
```

## Monitoring and Management

### Accessing Services

```bash
# Frontend (LoadBalancer service)
kubectl get svc -n gitops-app frontend-app
# Note the EXTERNAL-IP and access via browser

# Backend API
kubectl get svc -n gitops-app backend-api

# Argo CD
kubectl port-forward -n argocd svc/argocd-server 8080:443
# https://localhost:8080

# Prometheus (if Linkerd dashboard is installed)
linkerd viz install | kubectl apply -f -
linkerd viz dashboard

# View logs
kubectl logs -n gitops-app deployment/backend-api -f
kubectl logs -n gitops-app deployment/frontend-app -f
```

### Health Checks

Services include health check endpoints:

```bash
# Backend health
kubectl port-forward -n gitops-app svc/backend-api 3000:80
curl http://localhost:3000/health
curl http://localhost:3000/readiness

# Frontend
curl http://localhost:3000/
```

### Scaling

Manual scaling:
```bash
kubectl scale deployment backend-api -n gitops-app --replicas=5
```

Automatic scaling (HPA):
- Backend: 3-10 replicas, 70% CPU threshold
- Frontend: 3-8 replicas, 70% CPU threshold

## Troubleshooting

### Common Issues

**1. Terraform Plan Fails**
```bash
# Check authentication
gcloud auth application-default login

# Verify APIs are enabled
gcloud services list --enabled
```

**2. Cluster Unreachable**
```bash
# Re-authenticate
gcloud container clusters get-credentials gitops-cluster \
  --region us-central1 \
  --project $GCP_PROJECT_ID

# Check cluster status
gcloud container clusters describe gitops-cluster \
  --region us-central1 \
  --project $GCP_PROJECT_ID
```

**3. Pods Not Starting**
```bash
# Check pod status
kubectl describe pod <pod-name> -n gitops-app

# Check events
kubectl get events -n gitops-app

# Check logs
kubectl logs <pod-name> -n gitops-app -f
```

**4. Argo CD Sync Issues**
```bash
# Check app status
kubectl get application -n argocd gitops-app

# View sync logs
kubectl describe application gitops-app -n argocd

# Manually sync
argocd app sync gitops-app
```

**5. GitHub Actions Authentication**
```bash
# Verify secret tokens
kubectl get secret -n argocd github-repo-creds -o yaml

# Re-create secret with correct credentials
kubectl delete secret github-repo-creds -n argocd
kubectl create secret generic github-repo-creds \
  --from-literal=username=your-username \
  --from-literal=password=your-token \
  -n argocd
```

### Debug Commands

```bash
# Get detailed cluster info
kubectl cluster-info
kubectl get nodes -o wide
kubectl top nodes

# Check resource usage
kubectl top pods -n gitops-app

# Describe Argo CD application
kubectl describe application gitops-app -n argocd

# Check ingress
kubectl get ingress -n gitops-app
kubectl describe ingress gitops-ingress -n gitops-app

# Linkerd debugging
linkerd check
linkerd edges -n gitops-app
```

## Contributing

1. Create a feature branch
2. Make your changes
3. Push to GitHub
4. Create a Pull Request
5. CI/CD pipelines will automatically validate
6. Once approved, merge to main
7. GitOps will automatically deploy changes

## Best Practices Implemented

✅ Infrastructure as Code (Terraform)
✅ Configuration Management (Ansible)
✅ Container security (non-root users, read-only filesystems)
✅ Resource limits and requests
✅ Health checks and probes
✅ Auto-scaling (HPA)
✅ Pod anti-affinity for resilience
✅ GitOps workflow with Argo CD
✅ Service mesh with Linkerd
✅ Workload Identity for secure GCP access
✅ CI/CD automation with GitHub Actions
✅ Secrets management
✅ Network policies
✅ Comprehensive documentation

## License

MIT License - See LICENSE file for details

## Support

For issues, questions, or contributions, please open a GitHub issue.

---

**Built with**: Terraform • Ansible • Kubernetes • Argo CD • Linkerd • GitHub Actions • Google Cloud Platform
