resource "minio_s3_bucket" "state" {
  bucket = var.state_bucket
  acl    = "private"
}

resource "minio_s3_bucket_versioning" "state" {
  bucket = minio_s3_bucket.state.bucket

  versioning_configuration {
    status = "Enabled"
  }
}

resource "minio_iam_policy" "state" {
  name = "tofu-state-rw"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListStateBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          "arn:aws:s3:::${var.state_bucket}"
        ]
      },
      {
        Sid    = "ReadWriteStateObjects"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:GetObjectTagging",
          "s3:PutObjectTagging",
          "s3:DeleteObjectTagging"
        ]
        Resource = [
          "arn:aws:s3:::${var.state_bucket}/*"
        ]
      }
    ]
  })
}

resource "minio_iam_user" "state" {
  name          = var.tofu_state_access_key
  secret        = var.tofu_state_secret_key
  update_secret = false

  lifecycle {
    ignore_changes = [secret]
  }
}

resource "minio_iam_user_policy_attachment" "state" {
  user_name   = minio_iam_user.state.name
  policy_name = minio_iam_policy.state.id
}
