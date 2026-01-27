variable "project_id" {
  type        = string
  description = "GCP project id"
}

variable "region" {
  type        = string
  description = "GCP region"
  default     = "us-central1-a"
}

variable "zone" {
  type        = string
  description = "GCP zone (optional for zonal clusters)"
  default     = "us-central1-a"
}

variable "credentials_file" {
  type        = string
  description = "Path to service account JSON key file (use empty string to rely on env var)"
  default     = ""
}

variable "network_name" {
  type        = string
  description = "VPC network name"
  default     = "gke-vpc"
}

variable "subnet_name" {
  type        = string
  description = "Subnet name"
  default     = "gke-subnet-a"
}

variable "subnet_cidr" {
  type        = string
  description = "Primary CIDR for the subnet"
  default     = "10.0.0.0/20"
}

variable "pods_secondary_range" {
  type        = string
  description = "Secondary range for pods (alias IP)"
  default     = "10.4.0.0/14"
}

variable "services_secondary_range" {
  type        = string
  description = "Secondary range for services (alias IP)"
  default     = "10.8.0.0/20"
}

variable "cluster_name" {
  type        = string
  description = "GKE cluster name"
  default     = "dev-gke-cluster"
}

variable "node_count" {
  type        = number
  description = "Number of nodes in the primary node pool"
  default     = 2
}

variable "node_machine_type" {
  type        = string
  description = "Machine type for nodes"
  default     = "e2-medium"
  

}