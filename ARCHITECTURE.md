# GitOps Architecture Overview

## System Architecture Diagram

```
┌────────────────────────────────────────────────────────────────────────┐
│                         GitHub Repository                              │
│                                                                         │
│  ┌─ Infrastructure Code     ┌─ Application Code                        │
│  │  ├─ Terraform IaC        │  ├─ Backend (Node.js)                    │
│  │  ├─ Ansible Playbooks    │  ├─ Frontend (React)                     │
│  │  └─ CI/CD Workflows      │  └─ Kubernetes Manifests                 │
│  └──────────────────────────┴──────────────────────────────────────────┘
│                                     │
└─────────────────────────────────────┼──────────────────────────────────┘
                                      │
                    ┌─────────────────▼──────────────────┐
                    │  GitHub Actions CI/CD Pipelines    │
                    │                                    │
                    │  ├─ Build & Test                  │
                    │  ├─ Docker Build & Push           │
                    │  ├─ Terraform Plan & Apply        │
                    │  └─ Update Git Manifests          │
                    └─────────────────┬──────────────────┘
                                      │
         ┌────────────────────────────▼────────────────────────────┐
         │    Google Cloud Platform (GCP)                         │
         │                                                         │
         │  ┌─ Google Container Registry (GCR)                   │
         │  │  ├─ backend:latest                                │
         │  │  └─ frontend:latest                               │
         │  │                                                   │
         │  ├─ VPC Network                                      │
         │  │  ├─ Subnet: 10.0.0.0/20                          │
         │  │  ├─ Pod CIDR: 10.4.0.0/14                        │
         │  │  └─ Service CIDR: 10.8.0.0/20                    │
         │  │                                                   │
         │  └─ GKE Cluster (gitops-cluster)                     │
         │     ├─ 3+ Nodes (auto-scaling)                       │
         │     ├─ Network Policies enabled                      │
         │     └─ Workload Identity enabled                     │
         └─────────────────────────────────────────────────────┘
                              │
                              ▼
         ┌────────────────────────────────────────────────────────┐
         │          Kubernetes Cluster                            │
         │                                                         │
         │  ┌──────────────────────────────────────────────────┐ │
         │  │  argocd Namespace                                │ │
         │  │  ├─ Argo CD Server                              │ │
         │  │  ├─ Argo CD Application Controller              │ │
         │  │  └─ Argo CD Repository Server                  │ │
         │  └──────────────────────────────────────────────────┘ │
         │                                                         │
         │  ┌──────────────────────────────────────────────────┐ │
         │  │  linkerd Namespace                               │ │
         │  │  ├─ Linkerd Control Plane                        │ │
         │  │  ├─ Mutual TLS (mTLS)                            │ │
         │  │  └─ Traffic Management                           │ │
         │  └──────────────────────────────────────────────────┘ │
         │                                                         │
         │  ┌──────────────────────────────────────────────────┐ │
         │  │  gitops-app Namespace                            │ │
         │  │                                                  │ │
         │  │  ┌─ Backend Service ◄─────┐                     │ │
         │  │  │ - 3 Replicas (HPA)      │                    │ │
         │  │  │ - Liveness/Readiness    │                    │ │
         │  │  │ - Service Mesh Injected │                    │ │
         │  │  └────────────────────────┐│                    │ │
         │  │                            ││                    │ │
         │  │                            ▼▼                    │ │
         │  │  ┌─ Frontend Service ─► Ingress/LB             │ │
         │  │  │ - 3 Replicas (HPA)                           │ │
         │  │  │ - Liveness/Readiness                         │ │
         │  │  │ - Service Mesh Injected                      │ │
         │  │  └──────────────────────────────────────────┘   │ │
         │  │                                                  │ │
         │  │  Linkerd Proxy Sidecar (Injected)               │ │
         │  │  - mTLS for secure communication                │ │
         │  │  - Traffic metrics collection                   │ │
         │  │  - Automatic retries & timeouts                 │ │
         │  └──────────────────────────────────────────────────┘ │
         │                                                         │
         └─────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌───────────────────────┐
                    │   End Users / Clients │
                    │                       │
                    │  Frontend (Browser)   │
                    │  Mobile/Desktop Apps  │
                    │  API Consumers        │
                    └───────────────────────┘
```

## Data Flow

### 1. Development Workflow
```
Developer commits code
        ↓
Push to GitHub main branch
        ↓
GitHub Actions CI/CD Triggered
        ├─ Lint & Test Code
        ├─ Build Docker Images
        ├─ Push to GCR
        └─ Update K8s Manifests
        ↓
Git Commit with Updated Images
        ↓
Argo CD Detects Changes
        ↓
Automatic Sync to Cluster
```

### 2. Request Flow
```
User/Client Request
        ↓
Internet → Load Balancer (GCP)
        ↓
Kubernetes Ingress
        ↓
Frontend Service
        ├─ Linkerd mTLS Proxy
        └─ Frontend Pod
        ↓
API Request to Backend
        ├─ Linkerd mTLS Proxy
        └─ Backend Pod
        ↓
Response Back to User
```

## Component Architecture

### Infrastructure Layer (Terraform)
```
terraform/
├── main.tf
│   ├── Google Provider Config
│   ├── VPC Network & Subnet
│   ├── GKE Cluster Config
│   ├─┬ Node Pool (Auto-scaling)
│   │ └─ Machine Configuration
│   ├─ Service Account (Workload Identity)
│   └─ Cloud Storage Bucket
├── variables.tf
│   ├─ GCP Project ID
│   ├─ Region & CIDR Ranges
│   ├─ Node Configuration
│   └─ Feature Flags
└── outputs.tf
    ├─ Cluster Endpoint
    ├─ Network Names
    └─ Service Account Details
```

### Configuration Layer (Ansible)
```
ansible/
├── setup-cluster.yml
│   ├─ Get Cluster Credentials
│   ├─ Create Namespaces
│   ├─ Add Helm Repositories
│   ├─ Install Argo CD
│   ├─ Install Linkerd
│   ├─ Wait for Readiness
│   └─ Configure Workload Identity
├── inventory.ini
│   └─ Localhost Configuration
└── ansible.cfg
    └─ Connection & Role Settings
```

### Application Layer
```
Backend (Node.js)
├── server.js
│   ├─ Express Setup
│   ├─ Routes (/api/v1/*)
│   ├─ Health Checks
│   └─ Error Handling
├── package.json
│   ├─ express
│   └─ cors
└── Dockerfile
    ├─ FROM node:18-alpine
    ├─ WORKDIR /app
    ├─ Install Deps
    ├─ Copy App Code
    ├─ Health Check
    └─ CMD ["node", "server.js"]

Frontend (React)
├── App.js
│   ├─ Main Component
│   ├─ API Integration
│   └─ User Interface
├── package.json
│   ├─ react
│   ├─ axios
│   └─ react-router-dom
└── Dockerfile
    ├─ Multi-stage Build
    ├── Builder Stage
    │   ├─ npm install
    │   └─ npm run build
    └── Production Stage
        ├─ serve static files
        └─ Expose Port 3000
```

### Kubernetes Layer
```
Kubernetes Manifests
├── namespace.yaml
│   └─ gitops-app Namespace
├── backend-deployment.yaml
│   ├─ 3 Replicas (HPA: 3-10)
│   ├─ Liveness Probe
│   ├─ Readiness Probe
│   ├─ Resource Limits
│   ├─ Pod Anti-affinity
│   └─ Linkerd Injection
├── backend-service.yaml
│   ├─ ClusterIP Service
│   └─ Port 80 → 3000
├── frontend-deployment.yaml
│   ├─ 3 Replicas (HPA: 3-8)
│   ├─ Liveness Probe
│   ├─ Readiness Probe
│   ├─ Resource Limits
│   ├─ Pod Anti-affinity
│   └─ Linkerd Injection
├── frontend-service.yaml
│   ├─ LoadBalancer Service
│   └─ Port 80 → 3000
├── ingress.yaml
│   ├─ GCP Ingress
│   ├─ example.com → Frontend
│   ├─ api.example.com → Backend
│   └─ Managed Certificates
├── backend-hpa.yaml
│   ├─ Min: 3, Max: 10 Replicas
│   └─ CPU & Memory Thresholds
└── frontend-hpa.yaml
    ├─ Min: 3, Max: 8 Replicas
    └─ CPU & Memory Thresholds
```

### GitOps Layer (Argo CD)
```
argocd/
├── gitops-app.yaml
│   ├─ Application Definition
│   ├─ Git Repo Source
│   ├─ Auto Sync Enabled
│   ├─ Prune Enabled
│   └─ Self-heal Enabled
├── argocd-config.yaml
│   ├─ RBAC Policies
│   ├─ Repository Config
│   └─ URL Configuration
├── github-credentials.yaml
│   └─ Git Authentication
└── app-project.yaml
    ├─ AppProject Definition
    ├─ Source Repos Whitelist
    ├─ Destination Namespaces
    └─ Cluster Resources
```

### CI/CD Layer (GitHub Actions)
```
.github/workflows/
├── backend.yml
│   ├─ Trigger: backend/* changes
│   ├─ Steps:
│   │  ├─ Checkout Code
│   │  ├─ Auth to GCP
│   │  ├─ Build Image
│   │  ├─ Push to GCR
│   │  ├─ Update Manifest
│   │  └─ Commit & Push
│   └─ Triggers Argo CD Sync
├── frontend.yml
│   ├─ Same as Backend
│   └─ Triggers Argo CD Sync
└── terraform.yml
    ├─ Trigger: terraform/* changes
    ├─ Steps:
    │  ├─ Validate
    │  ├─ Plan
    │  └─ Apply (on main)
    └─ Updates GKE Cluster
```

## Security Architecture

### Network Security
```
Internet
    ↓
GCP Cloud Armor (Optional)
    ↓
GCP Load Balancer
    ↓
Kubernetes Ingress
    ↓
Network Policies
    ├─ gitops-app namespace isolation
    ├─ Deny ingress by default
    └─ Allow specific traffic
    ↓
Service Mesh (Linkerd)
    ├─ mTLS encryption
    ├─ Automatic certificate rotation
    └─ Traffic authorization policies
```

### Identity & Access Control
```
GCP Service Accounts
├─ terraform-sa: Infrastructure provisioning
├─ github-actions: CI/CD operations
├─ gitops-cluster-app: Pod authentication
└─ Workload Identity Federation

Kubernetes RBAC
├─ ServiceAccounts
├─ Roles & ClusterRoles
├─ RoleBindings
└─ Network Policies
```

### Data Security
```
Secrets Management
├─ GitHub Credentials (K8s Secret)
├─ Service Account Keys
├─ Environment Variables
└─ ConfigMaps (non-sensitive)

Encryption
├─ Application Layer: HTTPS/TLS
├─ Network Layer: mTLS (Linkerd)
├─ Storage Layer: GCP Managed Keys
└─ Transit: All traffic encrypted
```

## Scaling Strategy

### Horizontal Scaling (Replicas)
```
Backend API:
├─ Minimum Replicas: 3
├─ Maximum Replicas: 10
├─ Scale Trigger: 70% CPU / 80% Memory
└─ Pod Anti-affinity: Spread across nodes

Frontend App:
├─ Minimum Replicas: 3
├─ Maximum Replicas: 8
├─ Scale Trigger: 70% CPU / 80% Memory
└─ Pod Anti-affinity: Spread across nodes
```

### Vertical Scaling (Node Capacity)
```
GKE Auto-scaling:
├─ Minimum Nodes: 2
├─ Maximum Nodes: 10
├─ Machine Type: n1-standard-2
├─ Disk Size: 50 GB
└─ Auto-repair & Auto-upgrade: Enabled
```

## High Availability

### Application HA
```
Multiple Replicas (3+)
    ├─ Liveness Probes → Auto-restart failed pods
    ├─ Readiness Probes → Remove unhealthy from load balancer
    ├─ Resource Limits → Fair scheduling
    └─ Pod Anti-affinity → Spread across nodes
```

### Cluster HA
```
Multi-zone Nodes (via node pool distribution)
    ├─ Automatic failover
    ├─ Auto-repair: Replaces unhealthy nodes
    ├─ Auto-upgrade: Maintains cluster version
    └─ Load balancing across zones
```

### Data HA
```
Persistent Volumes (if needed)
    ├─ GCP Standard/Regional Disks
    ├─ Multi-zone replication
    └─ Snapshots for backups

ConfigMaps & Secrets
    ├─ Stored in etcd (replicated)
    └─ Backed by GCP managed storage
```

## Disaster Recovery

### Backup Strategy
```
1. Git Repository
   └─ Source of truth for all manifests
   
2. Terraform State
   └─ GCP Cloud Storage (versioned)
   
3. Application Data
   └─ Cloud SQL backups (if applicable)
   
4. Cluster Configuration
   └─ Argo CD tracks state
```

### Recovery Procedures
```
Infrastructure Loss:
├─ terraform apply (recreates from IaC)
└─ Time to recover: 10-15 minutes

Application Rollback:
├─ Revert Git commit
├─ Argo CD auto-syncs
└─ Time to recover: 2-5 minutes

Cluster Failure:
├─ GCP auto-provisioning
├─ Argo CD redeploys apps
└─ Time to recover: 20-30 minutes
```

## Monitoring & Observability

### Metrics Collection
```
Prometheus Scrapes (optional)
    ├─ Kubernetes Metrics
    │  ├─ CPU, Memory, Network
    │  └─ Pod, Node, Cluster metrics
    ├─ Application Metrics
    │  ├─ Request latency
    │  ├─ Error rates
    │  └─ Custom metrics
    └─ Linkerd Metrics
       ├─ Service traffic
       ├─ Latency
       └─ Success rates
```

### Logging
```
Pod Logs
    ├─ kubectl logs (direct access)
    ├─ GCP Cloud Logging (centralized)
    └─ Aggregation & filtering

Audit Logs
    ├─ Kubernetes API audit
    ├─ GCP Cloud Audit Logs
    └─ Compliance tracking
```

### Alerting
```
Conditions to Monitor
    ├─ Pod CrashLoopBackOff
    ├─ Node NotReady
    ├─ High CPU/Memory usage
    ├─ Ingress errors (5xx)
    └─ Argo CD sync failures

Alert Actions
    ├─ Slack notifications
    ├─ PagerDuty escalation
    └─ Auto-remediation (in some cases)
```

---

**Last Updated**: February 2024
**Version**: 1.0
