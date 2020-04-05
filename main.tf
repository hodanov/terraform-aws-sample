provider "aws" {
  region = "ap-northeast-1"
}

module "describe_regions_for_ec2" {
  source     = "./iam_role"
  name       = "describe-regions-for-ec2"
  identifier = "ec2.amazonaws.com"
  policy     = data.aws_iam_policy_document.allow_describe_regions.json
}

data "aws_iam_policy_document" "allow_describe_regions" {
  statement {
    effect    = "Allow"
    actions   = ["ec2:DescribeRegions"]
    resources = ["*"]
  }
}

# module "create_s3_buckets" {
#   source = "./s3"
# }
#
# module "build_vpc_nw_and_security_grp" {
#   source = "./network"
# }

# module "example_sg" {
#   source      = "./security_group"
#   name        = "module-sg"
#   vpc_id      = aws_vpc.example.id
#   port        = 80
#   cidr_blocks = ["0.0.0.0/0"]
# }
