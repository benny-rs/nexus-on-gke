variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for all resources"
  type        = string
  default     = "asia-southeast2"
}

variable "zone" {
  description = "GCP zone for the GKE node pool"
  type        = string
  default     = "asia-southeast2-a"
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "nexus-cluster"
}

variable "gcs_bucket_name" {
  description = "Name of the GCS bucket used as Nexus blob store"
  type        = string
}

variable "nexus_gsa_name" {
  description = "Name of the Google Service Account used by Nexus"
  type        = string
  default     = "nexus-sa"
}
