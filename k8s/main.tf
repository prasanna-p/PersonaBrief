provider "google" {
  project = var.project_id
  region  = "us-central1"
}

data "google_client_config" "default" {}

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

provider "helm" {
  kubernetes {
    host                   = data.google_container_cluster.primary.endpoint
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(data.google_container_cluster.primary.master_auth.0.cluster_ca_certificate)
  }
}

# Create GKE Cluster
resource "google_container_cluster" "primary" {
  name     = "persona-brief-cluster"
  location = "us-central1-a"

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

# ✅ Install Nginx Ingress Controller (First)
resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
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

# ✅ Install Cert-Manager (Depends on Ingress)
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

  depends_on = [helm_release.nginx_ingress] # Cert-manager needs Ingress first
}

# ✅ Create Let's Encrypt ClusterIssuer (Depends on Cert-Manager)
# resource "kubernetes_manifest" "letsencrypt_cluster_issuer" {
#   depends_on = [helm_release.cert_manager] # ClusterIssuer needs Cert-Manager

#   manifest = {
#     apiVersion = "cert-manager.io/v1"
#     kind       = "ClusterIssuer"
#     metadata = {
#       name = "letsencrypt-prod"
#     }
#     spec = {
#       acme = {
#         email  = "prasannap.jon@gmail.com"
#         server = "https://acme-v02.api.letsencrypt.org/directory"
#         privateKeySecretRef = {
#           name = "letsencrypt-prod"
#         }
#         solvers = [
#           {
#             http01 = {
#               ingress = {
#                 class = "nginx"
#               }
#             }
#           }
#         ]
#       }
#     }
#   }
# }

# Define Variables
variable "project_id" {
  description = "GCP Project ID"
}
