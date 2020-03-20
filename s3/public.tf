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
