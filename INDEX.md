# GitOps Kubernetes on GCP - Complete Project

A production-ready GitOps implementation showcasing:

## Features Implemented

✅ **Infrastructure as Code (Terraform)**
- GCP VPC with custom subnets
- Google Kubernetes Engine (GKE) cluster
- Auto-scaling node pools
- Service accounts and workload identity
- Cloud Storage for artifacts

✅ **Configuration Management (Ansible)**
- Automated cluster setup
- Argo CD installation
- Linkerd service mesh installation
- Workload identity binding

✅ **Container Applications**
- **Backend**: Node.js/Express REST API
  - Health check endpoints
  - User management API
  - Docker containerized
  - Kubernetes deployment-ready

- **Frontend**: React single-page application
  - API integration
  - Responsive design
  - Tech stack showcase
  - Multi-stage Docker build

✅ **Kubernetes Orchestration**
- Namespace isolation
- Deployment manifests
- Service definitions (ClusterIP, LoadBalancer)
- Ingress configuration
- Horizontal Pod Autoscaling (HPA)
- Liveness and readiness probes
- Resource limits and requests
- Pod anti-affinity

✅ **GitOps with Argo CD**
- Automated application deployment
- Git-driven synchronization
- Self-healing and auto-pruning
- AppProject and RBAC
- GitHub credentials management

✅ **Service Mesh (Linkerd)**
- mTLS encryption
- Traffic management
- Service observability
- Sidecar injection

✅ **CI/CD Pipeline (GitHub Actions)**
- Automated Docker builds
- Container registry pushes
- Image manifest updates
- Infrastructure-as-code deployments
- Pull request validations

✅ **Documentation**
- Comprehensive README
- Step-by-step deployment guide
- Architecture diagrams
- Local development setup

## Project Structure

```
gitops-k8s-gcp/
├── terraform/          # Infrastructure provisioning
├── ansible/            # Configuration management
├── backend/            # Node.js API server
├── frontend/           # React web application
├── kubernetes/         # K8s manifests
├── argocd/            # Argo CD configurations
├── .github/workflows/  # GitHub Actions CI/CD
├── docker-compose.yml # Local development
├── README.md          # Main documentation
├── DEPLOYMENT.md      # Deployment guide
├── ARCHITECTURE.md    # Architecture overview
├── LOCAL_DEV.md       # Local development guide
└── setup.sh           # Automated setup script
```

## Quick Start

### Prerequisites
- GCP Account with billing
- Google Cloud SDK
- Terraform, Ansible, kubectl, Docker

### Setup (Automated)
```bash
bash setup.sh
```

### Setup (Manual)
```bash
# 1. Configure GCP
gcloud config set project YOUR_PROJECT_ID
gcloud services enable compute.googleapis.com container.googleapis.com

# 2. Provision infrastructure
cd terraform
terraform init
terraform apply -var-file=terraform.tfvars

# 3. Setup cluster
cd ../ansible
ansible-playbook setup-cluster.yml

# 4. Deploy applications
kubectl apply -f kubernetes/
kubectl apply -f argocd/
```

## Key Components

### Terraform
- VPC network with custom CIDR ranges
- GKE cluster with network policies
- Auto-scaling node pools
- Workload identity configuration
- Cloud Storage bucket

### Ansible
- GKE credential management
- Argo CD Helm installation
- Linkerd service mesh setup
- Namespace creation
- ServiceAccount binding

### Backend API
- Express.js server
- REST endpoints
- Health/readiness probes
- Docker multi-layer build
- Kubernetes-ready deployment

### Frontend App
- React with axios
- User management UI
- Tech stack showcase
- Environment-based configuration
- Responsive styling

### Kubernetes
- 3 replicas per service
- HPA with CPU/memory thresholds
- Ingress with LoadBalancer
- Network policies
- Linkerd sidecar injection

### Argo CD
- Git-driven deployments
- Automated syncing
- RBAC policies
- AppProject management

### CI/CD
- Build triggers on code changes
- Docker image builds
- GCR pushes
- Manifest updates
- Terraform deployments

## Security Features

- Workload Identity for GCP API access
- mTLS with Linkerd
- Network policies
- Pod security standards
- Service account separation
- Read-only root filesystems
- Non-root container users
- Resource request/limits

## Monitoring

- Kubernetes metrics (CPU, memory)
- Pod health probes
- Service mesh metrics
- Application logs
- Event tracking

## Cost Optimization

- Auto-scaling based on demand
- Preemptible node options
- Right-sized machine types
- Regional resources
- Managed Kubernetes (GKE)

## Next Steps

1. Customize applications for your needs
2. Setup domain names and HTTPS
3. Configure monitoring and alerting
4. Implement additional policies
5. Scale to multiple regions
6. Add data persistence
7. Setup disaster recovery

## Technologies

**Cloud Platform**: Google Cloud Platform (GCP)
**IaC**: Terraform
**Configuration**: Ansible
**Container Orchestration**: Kubernetes, Google Kubernetes Engine
**Service Mesh**: Linkerd
**GitOps**: Argo CD
**CI/CD**: GitHub Actions
**Backend**: Node.js, Express
**Frontend**: React
**Container Registry**: Google Container Registry (GCR)
**Storage**: Google Cloud Storage

## Learning Outcomes

This project demonstrates:
- Cloud infrastructure provisioning
- Infrastructure as Code practices
- Configuration management
- Container orchestration
- GitOps workflows
- Service mesh implementation
- CI/CD automation
- Kubernetes best practices
- DevOps tooling and processes

## Support

See documentation files for detailed information:
- **README.md**: Overview and comprehensive guide
- **DEPLOYMENT.md**: Step-by-step deployment
- **ARCHITECTURE.md**: System architecture
- **LOCAL_DEV.md**: Local development setup

---

**Status**: Complete and Production-Ready
**Last Updated**: February 2024
