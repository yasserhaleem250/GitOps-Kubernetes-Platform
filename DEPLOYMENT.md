# Deployment Guide

This guide provides step-by-step instructions for deploying the GitOps application to Kubernetes on GCP.

## Prerequisites Checklist

- [ ] GCP Account with billing enabled
- [ ] `gcloud` CLI installed and authenticated
- [ ] `terraform` v1.0+ installed
- [ ] `ansible` 2.10+ installed
- [ ] `kubectl` installed
- [ ] `docker` installed
- [ ] GitHub account and repository access
- [ ] Personal Access Token from GitHub

## Phase 1: GCP Setup (15 minutes)

### Step 1: Configure GCP Project

```bash
# Set environment variables
export GCP_PROJECT_ID="your-actual-project-id"
export GCP_REGION="us-central1"

# Authenticate with Google Cloud
gcloud auth login

# Set default project
gcloud config set project $GCP_PROJECT_ID

# Enable required APIs
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com
gcloud services enable servicenetworking.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
```

### Step 2: Create Terraform Service Account

```bash
# Create service account
gcloud iam service-accounts create terraform-sa \
  --display-name="Terraform Service Account" \
  --project=$GCP_PROJECT_ID

# Grant Compute Admin role
gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
  --member="serviceAccount:terraform-sa@${GCP_PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/compute.admin"

# Grant Container Admin role
gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
  --member="serviceAccount:terraform-sa@${GCP_PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/container.admin"

# Create and download key
gcloud iam service-accounts keys create terraform-key.json \
  --iam-account=terraform-sa@${GCP_PROJECT_ID}.iam.gserviceaccount.com

# Set environment variable
export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/terraform-key.json"
```

## Phase 2: Infrastructure Provisioning (20-30 minutes)

### Step 3: Configure Terraform

```bash
# Navigate to terraform directory
cd terraform

# Copy and edit terraform variables
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
project_id           = "your-gcp-project-id"
region               = "us-central1"
cluster_name         = "gitops-cluster"
environment          = "production"
node_count           = 3
min_nodes            = 2
max_nodes            = 10
machine_type         = "n1-standard-2"
use_preemptible_nodes = false
```

### Step 4: Create Infrastructure

```bash
# Initialize Terraform
terraform init

# Format and validate
terraform fmt -recursive
terraform validate

# Plan infrastructure
terraform plan -out=tfplan

# Show plan details
terraform show tfplan

# Apply configuration (takes 10-15 minutes)
terraform apply tfplan

# Save outputs
terraform output > ../gke-cluster-info.txt

# Go back to root
cd ..
```

## Phase 3: Cluster Configuration (10 minutes)

### Step 5: Configure kubectl

```bash
# Get cluster credentials
gcloud container clusters get-credentials gitops-cluster \
  --region $GCP_REGION \
  --project $GCP_PROJECT_ID

# Verify cluster access
kubectl cluster-info
kubectl get nodes
kubectl get nodes -o wide

# Verify node status
kubectl wait --for=condition=Ready node --all --timeout=300s
```

## Phase 4: Argo CD and Linkerd Setup (15 minutes)

### Step 6: Run Ansible Playbook

```bash
# Navigate to ansible directory
cd ansible

# Install required Python packages
pip install ansible==7.0.0 kubernetes==27.2.0 google-auth==2.20.0

# Update Ansible inventory if needed
cat inventory.ini  # Should show localhost

# Run setup playbook
ansible-playbook -i inventory.ini setup-cluster.yml \
  -e "gcp_project_id=$GCP_PROJECT_ID"

# This will:
# - Install Argo CD
# - Install Linkerd service mesh
# - Configure Kubernetes service accounts
# - Setup Workload Identity binding
```

### Step 7: Access Argo CD UI

```bash
# Get initial admin password
kubectl get secret -n argocd argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d

# Port forward to access UI (opens on localhost:8080)
kubectl port-forward -n argocd svc/argocd-server 8080:443 &

# Access: https://localhost:8080
# Username: admin
# Password: <from above command>
```

## Phase 5: GitHub Integration (10 minutes)

### Step 8: Setup GitHub Credentials

```bash
# Navigate back to root
cd ..

# Update Argo CD GitHub credentials
# 1. Generate GitHub Personal Access Token
#    - Go to https://github.com/settings/tokens
#    - Create token with 'repo' scope
#    - Copy the token

# 2. Update the credentials file
nano argocd/github-credentials.yaml
# Replace:
#   - your-github-username with your actual username
#   - your-github-personal-access-token with your token
#   - your-username/gitops-k8s-gcp with your repo path

# 3. Apply the credentials
kubectl apply -f argocd/github-credentials.yaml

# Verify secret was created
kubectl get secret -n argocd github-repo-creds
```

### Step 9: Configure Argo CD Application

```bash
# Update the Git repo URL in gitops-app.yaml
nano argocd/gitops-app.yaml
# Update: https://github.com/your-username/gitops-k8s-gcp

# Apply Argo CD configuration
kubectl apply -f argocd/argocd-config.yaml
kubectl apply -f argocd/app-project.yaml

# Apply the application
kubectl apply -f argocd/gitops-app.yaml

# Watch sync process
kubectl get application gitops-app -n argocd -w

# Check application status
kubectl describe application gitops-app -n argocd
```

## Phase 6: Application Deployment (5 minutes)

### Step 10: Deploy Application

```bash
# Create namespace (if not already created by Argo CD)
kubectl create namespace gitops-app

# Verify namespace
kubectl get namespace gitops-app

# Check deployment status
kubectl get deployment -n gitops-app
kubectl get pods -n gitops-app
kubectl get svc -n gitops-app

# Wait for pods to be ready
kubectl wait --for=condition=Ready pod \
  -l app in (backend-api,frontend-app) \
  -n gitops-app \
  --timeout=300s
```

### Step 11: Access Applications

```bash
# Get Frontend LoadBalancer IP
kubectl get svc frontend-app -n gitops-app

# Note the EXTERNAL-IP (may take a few minutes to assign)
# Access: http://<EXTERNAL-IP>

# Get Backend API
kubectl get svc backend-api -n gitops-app

# Test Backend (from within cluster or port-forward)
kubectl port-forward -n gitops-app svc/backend-api 3000:80
# Test: curl http://localhost:3000/api/v1/info
```

## Phase 7: GitHub Actions CI/CD Setup (10 minutes)

### Step 12: Configure GitHub Secrets

```bash
# In your GitHub repository:
# Settings > Secrets and variables > Actions

# Add the following secrets:

# 1. GCP_PROJECT_ID
# Value: your-gcp-project-id

# 2. SERVICE_ACCOUNT
# Value: github-actions@your-gcp-project-id.iam.gserviceaccount.com

# 3. WIP (Workload Identity Provider)
# See "Setting up Workload Identity" section in main README.md
```

### Step 13: Create GitHub Actions Service Account (Optional but Recommended)

```bash
# Create service account for CI/CD
gcloud iam service-accounts create github-actions \
  --display-name="GitHub Actions Service Account" \
  --project=$GCP_PROJECT_ID

# Grant necessary roles
gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
  --member="serviceAccount:github-actions@${GCP_PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/container.developer"

gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
  --member="serviceAccount:github-actions@${GCP_PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/storage.admin"
```

## Phase 8: Verification (10 minutes)

### Step 14: Verify Complete Setup

```bash
# Check all components
echo "=== Kubernetes Nodes ==="
kubectl get nodes

echo "=== Namespaces ==="
kubectl get namespaces

echo "=== Argo CD ==="
kubectl get deployment -n argocd

echo "=== Application Deployments ==="
kubectl get deployment -n gitops-app

echo "=== Services ==="
kubectl get svc -n gitops-app

echo "=== Argo CD Applications ==="
kubectl get application -n argocd

echo "=== Linkerd ==="
kubectl get deployment -n linkerd

echo "=== Pods Status ==="
kubectl get pods -n gitops-app -o wide
kubectl top pods -n gitops-app 2>/dev/null || echo "Metrics not yet available"
```

### Step 15: Test Applications

```bash
# Test Backend API
BACKEND_IP=$(kubectl get svc backend-api -n gitops-app -o jsonpath='{.spec.clusterIP}')
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl http://$BACKEND_IP:80/api/v1/info

# Test Frontend accessibility
FRONTEND_IP=$(kubectl get svc frontend-app -n gitops-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Frontend accessible at: http://$FRONTEND_IP"

# Create test user
curl -X POST http://$BACKEND_IP:80/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com"}'
```

## Monitoring

### View Logs

```bash
# Backend logs
kubectl logs -n gitops-app deployment/backend-api -f

# Frontend logs
kubectl logs -n gitops-app deployment/frontend-app -f

# Argo CD logs
kubectl logs -n argocd deployment/argocd-server -f

# Linkerd logs
kubectl logs -n linkerd deployment/linkerd-controller -f
```

### Health Checks

```bash
# Check cluster health
kubectl get componentstatuses

# Check Argo CD health
kubectl get deployment -n argocd -o wide

# Check application health
kubectl get pods -n gitops-app -o wide
kubectl describe deployment backend-api -n gitops-app
```

## Cleanup (When Done)

```bash
# Delete Kubernetes resources
kubectl delete application gitops-app -n argocd
kubectl delete namespace gitops-app

# Destroy infrastructure
cd terraform
terraform destroy -var-file=terraform.tfvars

# Clean up GCP service accounts
gcloud iam service-accounts delete terraform-sa@${GCP_PROJECT_ID}.iam.gserviceaccount.com
gcloud iam service-accounts delete github-actions@${GCP_PROJECT_ID}.iam.gserviceaccount.com
```

## Troubleshooting

If you encounter issues during deployment, refer to the Troubleshooting section in the main [README.md](./README.md).

## Next Steps

1. **Customize Applications**: Modify backend/frontend code as needed
2. **Setup Monitoring**: Implement Prometheus and Grafana
3. **Enable TLS**: Use Let's Encrypt with Certbot for HTTPS
4. **Setup Backups**: Configure GKE backup and disaster recovery
5. **Multi-region**: Extend setup to multiple GCP regions
6. **Advanced Networking**: Implement network policies and service mesh features
7. **Cost Optimization**: Use preemptible nodes and adjust resource limits

## Support

For detailed information, see [README.md](./README.md) and individual component documentation.
