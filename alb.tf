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

/*
---------------
Request forwarding
---------------
*/

// "aws_lb_target_group" defines what ALB forwards the request to.
// Here, this will be associated with the service of ECS.
resource "aws_lb_target_group" "example" {
  // "target_type" specifies EC2 instance, IP address(ECS Fargate), Lambda function, etc.
  // Defines vpc_id, port and protocol if specifying "ip" at target_type.
  // "deregistration_delay" defines the time that ALB waits before the deregistration of the target.
  name                 = "example"
  target_type          = "ip"
  vpc_id               = aws_vpc.example.id
  port                 = 80
  protocol             = "HTTP"
  deregistration_delay = 300

  health_check {
    path                = "/" // The path used for health check.
    healthy_threshold   = 5   // Number of health check executions before it is judged as normal.
    unhealthy_threshold = 2   // Number of health check executions before it is judged as error.
    timeout             = 5   // Timeout value(s)
    interval            = 30  // Execution interval(s)
    matcher             = 200 // HTTP status code used to determine normality.
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  depends_on = [aws_lb.example]
}

// "aws_lb_listener_rule" forwards the request to target_group.
resource "aws_lb_listener_rule" "example" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100 // The lower the number, the higher the priority.

  // "action" defines the target group of the request destination.
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example.arn
  }

  // "condition" specifies the condition.
  // "/*" matches on all paths.
  condition {
    field  = "path-pattern"
    values = ["/*"]
  }
}

/*
---------------
Route53
---------------
*/

// Define the below when using DNS.
// resource "aws_route53_zone" "test_example" {
//   name = "test.example.com"
// }
//
// data "aws_route53_record" "example" {
//   zone_id = data.aws_route53_zone.example.zone_id
//   name    = data.aws_route53_zone.example.name
//   type    = "A"
//
//   alias {
//     name                   = aws_lb.example.dns_name
//     zone_id                = aws_lb.example.zone_id
//     evaluate_target_health = true
//   }
// }
//
// output "domain_name" {
//   value = aws_route53_record.example.name
// }

/*
---------------
ACM...AWS Certificate Manager
---------------
*/

// Define the below when using ACM.
// resource "aws_acm_certificate" "example" {
//   // "subject_alternative_names" add sub domain.
//   // "validation_method" defines how to verify domain ownership.
//   domain_name               = aws_route53_record.example.name
//   subject_alternative_names = []
//   validation_method         = "DNS"
//
//   lifecycle {
//     create_before_destroy = true
//   }
// }
