output "gke_cluster_name" {
  value       = google_container_cluster.nexus_cluster.name
  description = "GKE cluster name"
}

output "gke_cluster_endpoint" {
  value       = google_container_cluster.nexus_cluster.endpoint
  description = "GKE cluster API endpoint"
  sensitive   = true
}

output "gcs_bucket_name" {
  value       = google_storage_bucket.nexus_artifacts.name
  description = "GCS bucket used as Nexus blob store"
}

output "nexus_gsa_email" {
  value       = google_service_account.nexus_sa.email
  description = "Email of the Nexus Google Service Account"
}

output "get_credentials_command" {
  value       = "gcloud container clusters get-credentials ${google_container_cluster.nexus_cluster.name} --zone ${var.zone} --project ${var.project_id}"
  description = "Run this to configure kubectl"
}
