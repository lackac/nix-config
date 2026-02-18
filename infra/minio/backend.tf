terraform {
  backend "s3" {
    bucket = "tofu-state"
    key    = "minio/terraform.tfstate"
    region = "us-east-1"

    endpoints = {
      s3 = "https://boron.at-larch.ts.net:9000"
    }

    use_path_style              = true
    use_lockfile                = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
  }
}
