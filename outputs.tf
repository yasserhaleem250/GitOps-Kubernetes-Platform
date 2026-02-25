output "kubernetes_cluster_name" {
  value       = google_container_cluster.primary.name
  description = "GKE Cluster Name"
}

output "kubernetes_cluster_host" {
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
  description = "GKE Cluster Host"
}

output "region" {
  value       = var.region
  description = "GCP region"
}

output "project_id" {
  value       = var.project_id
  description = "GCP Project ID"
}

output "kubernetes_network_name" {
  value       = google_compute_network.vpc.name
  description = "VPC Network name"
}

output "vpc_subnet_name" {
  value       = google_compute_subnetwork.subnet.name
  description = "VPC Subnet name"
}

output "service_account_email" {
  value       = google_service_account.app_sa.email
  description = "Service Account Email"
}

output "artifacts_bucket" {
  value       = google_storage_bucket.artifacts.name
  description = "Cloud Storage bucket for artifacts"
}
