resource "random_id" "suffix_gcp" {
  byte_length = 2
}

resource "google_project" "infra" {
  name       = "Suncoast Systems Infra"
  project_id = "suncoast-systems-infra-${random_id.suffix_gcp.hex}"
  org_id     = var.gcp_org_id
  billing_account = "${var.billing_account}"
}

resource "google_project_service" "logging" {
  project = google_project.infra.project_id
  service = "logging.googleapis.com"
}

resource "google_service_account" "alloy_logs" {
  account_id   = "alloy-logs"
  display_name = "Alloy GKE Log Writer"
  project      = google_project.infra.project_id
}

resource "google_project_iam_member" "log_writer" {
  project = google_project.infra.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.alloy_logs.email}"
}

resource "google_service_account_key" "key" {
  service_account_id = google_service_account.alloy_logs.name
  private_key_type   = "TYPE_GOOGLE_CREDENTIALS_FILE"
}

output "gcp_alloy_logs_credentials" {
  value     = google_service_account_key.key.private_key
  sensitive = true
}
