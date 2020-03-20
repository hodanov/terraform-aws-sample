variable "name" {}
variable "identifier" {}
variable "policy" {}

// "aws_iam_role" defines IAM role.
resource "aws_iam_role" "default" {
  name               = var.name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

// "aws_iam_policy_document" defines an assume policy.
// This is used by "aws_iam_role".
data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = [var.identifier]
    }
  }
}

// "aws_iam_policy" defines IAM policy.
resource "aws_iam_policy" "default" {
  name   = var.name
  policy = var.policy
}

// "aws_iam_role_policy_attachment" attach policy to role.
resource "aws_iam_role_policy_attachment" "default" {
  role       = aws_iam_role.default.name
  policy_arn = aws_iam_policy.default.arn
}

output "iam_role_arn" {
  value = aws_iam_role.default.arn
}

output "iam_role_name" {
  value = aws_iam_role.default.name
}
