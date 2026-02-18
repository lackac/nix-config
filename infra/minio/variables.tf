variable "minio_endpoint" {
  description = "MinIO API endpoint in host:port form"
  type        = string
  default     = "boron.at-larch.ts.net:9000"
}

variable "minio_root_user" {
  description = "MinIO root username used by OpenTofu provider"
  type        = string
  sensitive   = true
}

variable "minio_root_password" {
  description = "MinIO root password used by OpenTofu provider"
  type        = string
  sensitive   = true
}

variable "tofu_state_access_key" {
  description = "OpenTofu S3 backend access key"
  type        = string
}

variable "tofu_state_secret_key" {
  description = "OpenTofu S3 backend secret key"
  type        = string
  sensitive   = true
}

variable "mattermost_access_key" {
  description = "Mattermost S3 access key"
  type        = string
}

variable "mattermost_secret_key" {
  description = "Mattermost S3 secret key"
  type        = string
  sensitive   = true
}

variable "state_bucket" {
  description = "S3 bucket name for OpenTofu remote state"
  type        = string
  default     = "tofu-state"
}

variable "mattermost_bucket" {
  description = "S3 bucket used by Mattermost uploads"
  type        = string
  default     = "mattermost"
}
