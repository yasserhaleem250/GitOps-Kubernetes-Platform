#!/bin/bash

# GitOps Kubernetes Setup Script
# This script automates the initial setup of the GitOps environment

set -e

echo "🚀 GitOps Kubernetes on GCP - Setup Script"
echo "==========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}✗ $1 is not installed${NC}"
        return 1
    else
        echo -e "${GREEN}✓ $1 is installed${NC}"
        return 0
    fi
}

check_command "gcloud" || exit 1
check_command "terraform" || exit 1
check_command "ansible" || exit 1
check_command "kubectl" || exit 1
check_command "docker" || exit 1

echo ""
echo -e "${YELLOW}Reading configuration...${NC}"

# Read GCP Project ID
read -p "Enter your GCP Project ID: " GCP_PROJECT_ID
read -p "Enter GCP Region (default: us-central1): " GCP_REGION
GCP_REGION=${GCP_REGION:-us-central1}

export GCP_PROJECT_ID
export GCP_REGION

echo ""
echo -e "${GREEN}Configuration:${NC}"
echo "  Project ID: $GCP_PROJECT_ID"
echo "  Region: $GCP_REGION"
echo ""

# Setup GCP
echo -e "${YELLOW}Step 1: Configuring GCP...${NC}"

gcloud config set project $GCP_PROJECT_ID

# Enable APIs
echo "Enabling required APIs..."
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com
gcloud services enable servicenetworking.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com

echo -e "${GREEN}✓ GCP configured${NC}"
echo ""

# Create Terraform Service Account
echo -e "${YELLOW}Step 2: Creating Terraform Service Account...${NC}"

SA_NAME="terraform-sa"
gcloud iam service-accounts create $SA_NAME \
  --display-name="Terraform Service Account" \
  --project=$GCP_PROJECT_ID 2>/dev/null || echo "Service account already exists"

# Grant permissions
gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
  --member="serviceAccount:${SA_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/compute.admin" --quiet

gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
  --member="serviceAccount:${SA_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/container.admin" --quiet

# Create key
gcloud iam service-accounts keys create terraform-key.json \
  --iam-account=${SA_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com

export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/terraform-key.json"

echo -e "${GREEN}✓ Terraform service account created${NC}"
echo ""

# Configure Terraform
echo -e "${YELLOW}Step 3: Configuring Terraform...${NC}"

cd terraform

# Copy and update terraform.tfvars
if [ ! -f terraform.tfvars ]; then
    cp terraform.tfvars.example terraform.tfvars
    sed -i "s/your-gcp-project-id/$GCP_PROJECT_ID/" terraform.tfvars
    sed -i "s/us-central1/$GCP_REGION/" terraform.tfvars
    echo "Updated terraform.tfvars"
fi

terraform init
terraform fmt -recursive
terraform validate

echo -e "${GREEN}✓ Terraform configured${NC}"
echo ""

# Create Infrastructure
echo -e "${YELLOW}Step 4: Provisioning GKE Infrastructure...${NC}"
echo "This may take 10-15 minutes..."

terraform plan -out=tfplan -var-file=terraform.tfvars
terraform apply tfplan

terraform output > ../gke-cluster-info.txt

cd ..

echo -e "${GREEN}✓ Infrastructure provisioned${NC}"
echo ""

# Configure kubectl
echo -e "${YELLOW}Step 5: Configuring kubectl...${NC}"

CLUSTER_NAME="gitops-cluster"

gcloud container clusters get-credentials $CLUSTER_NAME \
  --region $GCP_REGION \
  --project $GCP_PROJECT_ID

kubectl cluster-info
kubectl wait --for=condition=Ready node --all --timeout=300s

echo -e "${GREEN}✓ kubectl configured${NC}"
echo ""

# Setup Argo CD and Linkerd
echo -e "${YELLOW}Step 6: Installing Argo CD and Linkerd...${NC}"

cd ansible

# Install Python dependencies
echo "Installing Ansible dependencies..."
pip install -q ansible==7.0.0 kubernetes==27.2.0 google-auth==2.20.0

# Run playbook
ansible-playbook -i inventory.ini setup-cluster.yml \
  -e "gcp_project_id=$GCP_PROJECT_ID"

cd ..

echo -e "${GREEN}✓ Argo CD and Linkerd installed${NC}"
echo ""

# Display next steps
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Next steps:"
echo ""
echo "1. Get Argo CD admin password:"
echo "   kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo ""
echo "2. Access Argo CD UI:"
echo "   kubectl port-forward -n argocd svc/argocd-server 8080:443 &"
echo "   https://localhost:8080"
echo ""
echo "3. Update GitHub credentials:"
echo "   nano argocd/github-credentials.yaml"
echo "   kubectl apply -f argocd/github-credentials.yaml"
echo ""
echo "4. Deploy application:"
echo "   kubectl apply -f argocd/gitops-app.yaml"
echo ""
echo "5. Access applications:"
echo "   kubectl get svc -n gitops-app"
echo ""
echo "Documentation:"
echo "  - README.md: Complete overview"
echo "  - DEPLOYMENT.md: Detailed deployment guide"
echo "  - ARCHITECTURE.md: Architecture diagrams"
echo "  - LOCAL_DEV.md: Local development setup"
echo ""
