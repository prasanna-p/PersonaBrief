variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-central1-a"
}

variable "cluster_name" {
  description = "Name of the GKE Cluster"
  type        = string
  default     = "persona-brief-cluster"
}

variable "node_pool_name" {
  description = "Name of the GKE Node Pool"
  type        = string
  default     = "primary-node-pool"
}

variable "machine_type" {
  description = "Machine type for nodes"
  type        = string
  default     = "e2-standard-2"
}

variable "namespace" {
  description = "Kubernetes Namespace"
  type        = string
  default     = "persona-brief"
}

variable "ksa_name" {
  description = "Kubernetes Service Account Name"
  type        = string
  default     = "persona-brief-ksa"
}

variable "service_account_name" {
  description = "Google Cloud Service Account"
  type        = string
}

variable "native_cidr" {
  description = "Cluster IPv4 CIDR for Cilium"
  type        = string
  default     = ""
}
