variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "cluster_name" {
  description = "GKE cluster name"
  type        = string
  default     = "gitops-cluster"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "subnet_cidr" {
  description = "CIDR range for subnet"
  type        = string
  default     = "10.0.0.0/20"
}

variable "pods_cidr" {
  description = "CIDR range for pods"
  type        = string
  default     = "10.4.0.0/14"
}

variable "services_cidr" {
  description = "CIDR range for services"
  type        = string
  default     = "10.8.0.0/20"
}

variable "node_count" {
  description = "Number of nodes in the node pool"
  type        = number
  default     = 3
}

variable "min_nodes" {
  description = "Minimum number of nodes in node pool"
  type        = number
  default     = 2
}

variable "max_nodes" {
  description = "Maximum number of nodes in node pool"
  type        = number
  default     = 10
}

variable "machine_type" {
  description = "Machine type for nodes"
  type        = string
  default     = "n1-standard-2"
}

variable "use_preemptible_nodes" {
  description = "Use preemptible nodes to reduce costs"
  type        = bool
  default     = false
}
