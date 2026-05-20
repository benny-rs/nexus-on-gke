terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# ---------------------------------------------------------------------------
# 1. GCS Bucket — Nexus blob store
# ---------------------------------------------------------------------------
resource "google_storage_bucket" "nexus_artifacts" {
  name          = var.gcs_bucket_name
  location      = var.region
  force_destroy = false

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "AbortIncompleteMultipartUpload"
    }
  }
}

# ---------------------------------------------------------------------------
# 2. Google Service Account — used by Nexus (via Workload Identity)
# ---------------------------------------------------------------------------
resource "google_service_account" "nexus_sa" {
  account_id   = var.nexus_gsa_name
  display_name = "Nexus Repository GCS Service Account"
}

resource "google_storage_bucket_iam_member" "nexus_sa_storage_admin" {
  bucket = google_storage_bucket.nexus_artifacts.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.nexus_sa.email}"
}

# ---------------------------------------------------------------------------
# 3. GKE Cluster (zonal, single-node, cost-optimised)
# ---------------------------------------------------------------------------
resource "google_container_cluster" "nexus_cluster" {
  name     = var.cluster_name
  location = var.zone

  remove_default_node_pool = true
  initial_node_count       = 1

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  networking_mode = "VPC_NATIVE"
  ip_allocation_policy {}
}

resource "google_container_node_pool" "nexus_nodes" {
  name       = "nexus-node-pool"
  cluster    = google_container_cluster.nexus_cluster.id
  location   = var.zone
  node_count = 1

  node_config {
    machine_type = "n1-standard-1"
    preemptible  = true

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    labels = {
      app = "nexus"
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

# ---------------------------------------------------------------------------
# 4. Workload Identity binding — KSA nexus/nexus-sa -> GSA nexus_sa
# ---------------------------------------------------------------------------
resource "google_service_account_iam_member" "workload_identity_binding" {
  service_account_id = google_service_account.nexus_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[nexus/nexus-sa]"
  depends_on = [google_container_node_pool.nexus_nodes]
}
