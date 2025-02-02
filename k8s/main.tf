provider "google" {
  project = var.project_id
  region  = "us-central1"
}

# Fetch Cluster Info
data "google_container_cluster" "primary" {
  name     = google_container_cluster.primary.name
  location = google_container_cluster.primary.location
  depends_on = [google_container_cluster.primary]
}

provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.primary.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
}

data "google_client_config" "default" {}

# Create GKE Cluster
resource "google_container_cluster" "primary" {
  name     = "persona-brief-cluster"
  location = "us-central1-a" # Single zone

  remove_default_node_pool = true
  initial_node_count       = 1

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
}

# Create a Node Pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "primary-node-pool"
  cluster    = google_container_cluster.primary.id
  location   = google_container_cluster.primary.location
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "e2-standard-2"
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }
}

# Create Kubernetes Namespace
resource "kubernetes_namespace" "persona_namespace" {
  metadata {
    name = "persona-brief"
  }
}

# Create Kubernetes Service Account
resource "kubernetes_service_account" "ksa" {
  metadata {
    name      = "persona-brief-ksa"
    namespace = kubernetes_namespace.persona_namespace.metadata[0].name
    annotations = {
      "iam.gke.io/gcp-service-account" = "personabrief@skillful-octane-360205.iam.gserviceaccount.com"
    }
  }
}

# IAM Binding for Workload Identity
resource "google_service_account_iam_binding" "workload_identity" {
  service_account_id = "projects/skillful-octane-360205/serviceAccounts/personabrief@skillful-octane-360205.iam.gserviceaccount.com"
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:skillful-octane-360205.svc.id.goog[persona-brief/persona-brief-ksa]"
  ]
}

# Variables
variable "project_id" {
  description = "GCP Project ID"
}








