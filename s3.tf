/*
---------------
S3 public bucket
---------------
*/

resource "aws_s3_bucket" "public" {
  bucket = "hoda-practice-terraform-public"

  // ACL is an option to define access control.
  acl = "public-read"

  // The cors_rule is an option to define CORS.
  cors_rule {
    allowed_origins = ["https://hogehoge-mogumogu.com"]
    allowed_methods = ["GET"]
    allowed_headers = ["*"]
    max_age_seconds = 3000
  }
}

/*
---------------
S3 private bucket
---------------
*/

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

/*
---------------
S3 log bucket
---------------
*/

resource "aws_s3_bucket" "alb_log" {
  bucket        = "hoda-practice-terraform-alb-log"
  force_destroy = true

  // lifecycle_rule is an option to define lifecycle rule.
  // Here, files that are 180 days old will be automatically deleted.
  lifecycle_rule {
    enabled = true

    expiration {
      days = "180"
    }
  }
}

resource "aws_s3_bucket_policy" "alb_log" {
  bucket = aws_s3_bucket.alb_log.id
  policy = data.aws_iam_policy_document.alb_log.json
}

// "aws_iam_policy_document" defines access right from sercvices of AWS such as ALB to S3.
data "aws_iam_policy_document" "alb_log" {
  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.alb_log.id}/*"]

    // The identifiers is the account ID. This is not your AWS account ID.
    // https://docs.aws.amazon.com/ja_jp/elasticloadbalancing/latest/classic/enable-access-logs.html
    principals {
      type        = "AWS"
      identifiers = ["582318560864"]
    }
  }
}
