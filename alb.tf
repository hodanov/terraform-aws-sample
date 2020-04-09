/*
---------------
Application Load Balancer
---------------
*/

// "aws_lb" defines application load balancer.
resource "aws_lb" "example" {
  // Specify "application" for load_balancer_type if you use ALB.
  // Specify "network" for load_balancer_type if you use NLB.
  // When specifying "false" for "internal", destination of ALB will be internet. Here, "internal" is specified as "false", so that it faces inside the VPC.
  name                       = "example"
  load_balancer_type         = "application"
  internal                   = false
  idle_timeout               = 60
  enable_deletion_protection = false

  // Specify public subnets in network.tf.
  subnets = [
    aws_subnet.public_0.id,
    aws_subnet.public_1.id,
  ]

  // Specify S3 bucket in s3.tf.
  access_logs {
    bucket  = aws_s3_bucket.alb_log.id
    enabled = true
  }

  security_groups = [
    module.http_sg.security_group_id,
    module.https_sg.security_group_id,
    module.http_redirect_sg.security_group_id,
  ]
}

output "alb_dns_name" {
  value = aws_lb.example.dns_name
}

/*
---------------
Security Group
---------------
*/

module "http_sg" {
  source      = "./security_group"
  name        = "http-sg"
  vpc_id      = aws_vpc.example.id
  port        = 80
  cidr_blocks = ["0.0.0.0/0"]
}

module "https_sg" {
  source      = "./security_group"
  name        = "https-sg"
  vpc_id      = aws_vpc.example.id
  port        = 443
  cidr_blocks = ["0.0.0.0/0"]
}

module "http_redirect_sg" {
  source      = "./security_group"
  name        = "https-redirect-sg"
  vpc_id      = aws_vpc.example.id
  port        = 8080
  cidr_blocks = ["0.0.0.0/0"]
}

/*
---------------
HTTP/HTTPS listener
---------------
*/

// "aws_lb_listener" defines ALB accepts requests from which port.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "これは「HTTP」です"
      status_code  = "200"
    }
  }
}
