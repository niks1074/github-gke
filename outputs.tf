output "project_id" {
  value       = var.project_id
  description = "GCP project id"
}

output "network_self_link" {
  value       = google_compute_network.vpc.self_link
  description = "Self link of the created VPC"
}

output "subnet_self_link" {
  value       = google_compute_subnetwork.subnet.self_link
  description = "Self link of the created subnet"
}

output "cluster_name" {
  value       = google_container_cluster.gke.name
  description = "GKE cluster name"
}

output "cluster_endpoint" {
  value       = google_container_cluster.gke.endpoint
  description = "GKE cluster endpoint (API server)"
}

output "cluster_ca_certificate" {
  value       = google_container_cluster.gke.master_auth[0].cluster_ca_certificate
  description = "Base64 encoded cluster CA certificate"
}