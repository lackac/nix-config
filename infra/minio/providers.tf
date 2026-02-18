provider "minio" {
  minio_server   = var.minio_endpoint
  minio_user     = var.minio_root_user
  minio_password = var.minio_root_password
  minio_ssl      = true
  minio_insecure = false
}
