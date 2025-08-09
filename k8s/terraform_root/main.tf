locals {
  native_cidr = data.google_container_cluster.primary.cluster_ipv4_cidr
}

data "google_client_config" "default" {}

# Fetch Cluster Info
data "google_container_cluster" "primary" {
  name     = google_container_cluster.primary.name
  location = google_container_cluster.primary.location
  depends_on = [google_container_cluster.primary]
}

# Create GKE Cluster
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.zone

  remove_default_node_pool = true
  initial_node_count       = 1

  deletion_protection = false  # ✅ Prevents the error during 'terraform destroy'

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
}

# Create a Node Pool
resource "google_container_node_pool" "primary_nodes" {
  name       = var.node_pool_name
  cluster    = google_container_cluster.primary.id
  location   = google_container_cluster.primary.location
  node_count = 2

  node_config {
    preemptible  = true
    machine_type = var.machine_type
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Apply Cilium-required taint
    taint {
      key    = "node.cilium.io/agent-not-ready"
      value  = "true"
      effect = "NO_EXECUTE"
    }
  }
}

# Create Kubernetes Namespace
resource "kubernetes_namespace" "persona_namespace" {
  metadata {
    name = var.namespace
  }
}

# Create GCP service account
resource "google_service_account" "persona_sa" {
  account_id   = var.service_account_name
  display_name = var.service_account_name

  
}

# Assign artifact registry role
resource "google_project_iam_member" "artifact_registry_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.persona_sa.email}"

  
}

# Assign Vertex Ai user role
resource "google_project_iam_member" "vertex_ai_user" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.persona_sa.email}"

  
}

# Create Kubernetes Service Account
resource "kubernetes_service_account" "ksa" {
  metadata {
    name      = var.ksa_name
    namespace = var.namespace
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.persona_sa.email
    }
  }
}

# IAM Binding for Workload Identity
resource "google_service_account_iam_binding" "workload_identity" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${google_service_account.persona_sa.email}"
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${var.project_id}.svc.id.goog[${var.namespace}/${var.ksa_name}]"
  ]
}

resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  namespace  = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.10.0"
  create_namespace = true

  values = [<<EOF
controller:
  service:
    annotations:
      cloud.google.com/load-balancer-type: "External"
EOF
  ]

}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  namespace  = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.16.3"
  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }

  depends_on = [helm_release.nginx_ingress]
}
