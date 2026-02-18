resource "minio_s3_bucket" "mattermost" {
  bucket = var.mattermost_bucket
  acl    = "private"
}

resource "minio_iam_policy" "mattermost" {
  name = "mattermost-rw"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListMattermostBucket"
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads"
        ]
        Resource = [
          "arn:aws:s3:::${var.mattermost_bucket}"
        ]
      },
      {
        Sid    = "ReadWriteMattermostObjects"
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:ListMultipartUploadParts",
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.mattermost_bucket}/*"
        ]
      }
    ]
  })
}

resource "minio_iam_user" "mattermost" {
  name          = var.mattermost_access_key
  secret        = var.mattermost_secret_key
  update_secret = false

  lifecycle {
    ignore_changes = [secret]
  }
}

resource "minio_iam_user_policy_attachment" "mattermost" {
  user_name   = minio_iam_user.mattermost.name
  policy_name = minio_iam_policy.mattermost.id
}
