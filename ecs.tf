# "aws_ecs_cluster" defines ECS cluster
# A ECS cluster is a resource that bundles host servers of docker containers logically.
resource "aws_ecs_cluster" "example" {
  name = "example"
}

# "aws_ecs_task_definition" sets the definition of the task
# A task definition is required to run Docker containers in Amazon ECS.
# You can define multiple containers in a task definition.
resource "aws_ecs_task_definition" "example" {
  # Defines the prefix of task name(family), the size of the resource(cpu, memory) and so on.
  family                   = "example"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  container_definitions    = file("./container_definitions.json")
}

# "aws_ecs_service" can define the number of tasks to launch.
resource "aws_ecs_service" "example" {
  # "desired_count" specifies the number of tasks to keep.
  name                              = "example"
  cluster                           = aws_ecs_cluster.example.arn
  task_definition                   = aws_ecs_task_definition.example.arn
  desired_count                     = 2
  launch_type                       = "FARGATE"
  platform_version                  = "1.3.0"
  health_check_grace_period_seconds = 60

  # "network_configuration" specifies subnets and security_groups.
  network_configuration {
    assign_public_ip = false
    security_groups  = [module.nginx_sg.security_group_id]

    subnets = [
      aws_subnet.private_0.id,
      aws_subnet.private_1.id,
    ]
  }

  # "load_balancer" is associated with the value specified by container_definitions in "aws_ecs_task_definition".
  load_balancer {
    target_group_arn = aws_lb_target_group.example.arn
    container_name   = "example"
    container_port   = 80
  }

  # In the case of Fargate, the task definition will be updated each time it is deployed,
  # and the difference will appear at the time of plan. Therefore, Terraform should ignore
  # task definition changes.
  lifecycle {
    ignore_changes = [task_definition]
  }
}

module "nginx_sg" {
  source      = "./security_group"
  name        = "nginx-sg"
  vpc_id      = aws_vpc.example.id
  port        = 80
  cidr_blocks = [aws_vpc.example.cidr_block]
}

