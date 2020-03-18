resource "aws_s3_bucket" "alb_log" {
  bucket = "hoda-practice-terraform-alb-log"

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

    // The identifiers is the account ID.
    principals {
      type        = "AWS"
      identifiers = ["xxxxx"]
    }
  }
}
