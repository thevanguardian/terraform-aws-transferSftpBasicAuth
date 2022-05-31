resource "aws_s3_bucket" "default_storage" {
  count         = lower(var.storageBackend) == "s3" ? 1 : 0
  bucket_prefix = "${local.common_name}-"
  force_destroy = false
}
resource "aws_s3_bucket_versioning" "default_storage" {
  count  = lower(var.storageBackend) == "s3" ? 1 : 0
  bucket = aws_s3_bucket.default_storage[0].id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "default_storage" {
  count  = lower(var.storageBackend) == "s3" ? 1 : 0
  bucket = aws_s3_bucket.default_storage[0].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
resource "aws_s3_bucket_acl" "default_storage" {
  count  = lower(var.storageBackend) == "s3" ? 1 : 0
  bucket = aws_s3_bucket.default_storage[0].id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "default_storage" {
  count  = lower(var.storageBackend) == "s3" ? 1 : 0
  bucket = aws_s3_bucket.default_storage[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_efs_file_system" "efs_storage" {
  count      = lower(var.storageBackend) == "efs" ? 1 : 0
  encrypted  = true
  kms_key_id = data.aws_kms_alias.efs.target_key_arn
  lifecycle_policy {
    transition_to_ia = "AFTER_90_DAYS"
  }
}

resource "aws_efs_access_point" "root" {
  count          = lower(var.storageBackend) == "efs" ? 1 : 0
  file_system_id = aws_efs_file_system.efs_storage[0].id
  posix_user {
    gid = 1000
    uid = 1000
  }
  root_directory {
    path = "/"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "0777"
    }
  }
}

resource "aws_efs_mount_target" "efs_storage" {
  for_each        = lower(var.storageBackend) == "efs" ? toset(flatten([var.subnetIds])) : []
  file_system_id  = aws_efs_file_system.efs_storage[0].id
  subnet_id       = each.value
  security_groups = [aws_security_group.lambda-efs[0].id]
}
