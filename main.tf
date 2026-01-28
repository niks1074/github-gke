# Enable required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "compute.googleapis.com",
    "container.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "servicenetworking.googleapis.com"
  ])

  project = var.project_id
  service = each.key

  disable_on_destroy = false
}

# VPC
resource "google_compute_network" "vpc" {
  name                    = var.network_name
  project                 = var.project_id
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

# Subnet with secondary ranges for GKE alias IPs
resource "google_compute_subnetwork" "subnet" {
  name                     = var.subnet_name
  project                  = var.project_id
  region                   = "us-central1"
  network                  = google_compute_network.vpc.self_link
  ip_cidr_range            = var.subnet_cidr
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pods_secondary_range
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.services_secondary_range
  }


}

# GKE cluster (regional)
resource "google_container_cluster" "gke" {
  name     = var.cluster_name
  location = var.region

  network    = google_compute_network.vpc.self_link
  subnetwork = google_compute_subnetwork.subnet.self_link

  remove_default_node_pool = true
  initial_node_count       = 1

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  # Basic master auth block (kept minimal)
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }
  deletion_protection = false   # 👈 add this line
   
   depends_on = [
    google_project_service.required_apis,
    google_compute_subnetwork.subnet
  ]

}

# Node pool
resource "google_container_node_pool" "primary" {
  name     = "primary-pool"
  cluster  = google_container_cluster.gke.name
  location = "us-central1-a"
  node_count = var.node_count

node_config {
    machine_type = var.node_machine_type
    disk_size_gb = 30            # reduce per-node disk size
    disk_type    = "pd-standard" # use standard PD instead of SSD
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [google_container_cluster.gke]
}