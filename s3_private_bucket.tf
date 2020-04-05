// "aws_s3_bucket" is a private bucket.
resource "aws_s3_bucket" "private" {
  bucket = "hoda-practice-terraform-private"

  // The versioning is an option to enable a restore.
  versioning {
    enabled = true
  }

  // The server_side_encryption_configuration is an option to enable an encryption of objects.
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

// "aws_s3_bucket_public_access_block" prevents unexpected publication of objects.
resource "aws_s3_bucket_public_access_block" "private" {
  bucket                  = aws_s3_bucket.private.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
