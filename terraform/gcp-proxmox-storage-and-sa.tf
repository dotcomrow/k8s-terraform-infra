
resource "google_service_account" "gcsfuse" {
  account_id   = "gcsfuse-mount"
  display_name = "GCS Fuse Mount Service Account"
}

resource "google_storage_bucket" "free_tier_safe_bucket" {
  name     = var.bucket_name
  location = var.region
  project  = google_project.infra.project_id
  force_destroy = true

  storage_class = "STANDARD"

  uniform_bucket_level_access = true

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = var.retention_days
    }
  }

  labels = {
    purpose = "free-tier-data-bucket"
  }
}

# Assign objectAdmin role to a specific bucket
resource "google_storage_bucket_iam_member" "bucket_object_admin" {
  bucket = google_storage_bucket.free_tier_safe_bucket.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.gcsfuse.email}"
}

# Optional: if you want project-wide permissions instead
# resource "google_project_iam_member" "object_admin" {
#   project = var.project_id
#   role    = "roles/storage.objectAdmin"
#   member  = "serviceAccount:${google_service_account.gcsfuse.email}"
# }

# Generate and store a key locally
resource "google_service_account_key" "gcsfuse_key" {
  service_account_id = google_service_account.gcsfuse.name
  keepers = {
    last_updated = timestamp()
  }
  private_key_type = "TYPE_GOOGLE_CREDENTIALS_FILE"
}

output "gcsfuse_service_account_key" {
  value     = google_service_account_key.gcsfuse_key.private_key
  sensitive = true
}

output "gcsfuse_service_account_email" {
  value = google_service_account.gcsfuse.email
}
