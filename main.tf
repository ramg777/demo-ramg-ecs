

# Create an ECS cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "ecs_cluster"
}

# Create a task definition for the ECS service
resource "aws_ecs_task_definition" "task_definition" {
  family                   = "task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"] # Stating that we are using ECS Fargate
  memory                   = 512         # Specifying the memory our container requires
  cpu                      = 256         # Specifying the CPU our container requires
  execution_role_arn       = "${aws_iam_role.testecsTaskExecutionRole.arn}"
  container_definitions    = <<DEFINITION
  [
    {
      "name": "my-container",
      "image": "${data.aws_ecr_repository.tessian-demo-ramg.repository_url}", 
      "portMappings": [
        {
          "containerPort": 8000,
          "hostPort": 8000,
          "protocol": "tcp"
        }
      ]
    }
  ]
  DEFINITION

}


resource "aws_lb" "test-lb" {
  name               = "test-lb"
  internal           = false
  load_balancer_type = "application"
  enable_deletion_protection = false
  security_groups   = [aws_security_group.ecs_sg.id]
  subnets           = [aws_subnet.pub-subnet1.id, aws_subnet.pub-subnet2.id]

  enable_http2      = true
}


resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.test-lb.arn
  port              = 443
  protocol          = "HTTPS"
  
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.my_target_group.id
    
  }

  certificate_arn = "arn:aws:acm:eu-west-2:071148681943:certificate/0b1aa564-2041-4411-851a-5e80c3aefd1e"  # Replace with your ACM certificate ARN
}

resource "aws_lb_target_group" "my_target_group" {
  name     = "my-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id

  target_type = "ip"

  health_check {
    path     = "/api/emails"
    interval = 120
  }
}

# resource "aws_lb_target_group_attachment" "ecs_attachment" {
#   target_group_arn = aws_lb_target_group.my_target_group.arn
#   target_id        = aws_ecs_task_definition.task_definition.arn
# }

resource "aws_ecs_service" "my_service" {
  name            = "my-ecs-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.task_definition.arn

  launch_type = "FARGATE"

  network_configuration {
    subnets = [aws_subnet.pub-subnet1.id, aws_subnet.pub-subnet2.id]
    security_groups = [aws_security_group.ecs_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.my_target_group.arn
    container_name   = "my-container"
    container_port   = 8000
  }
}


# # Create an ECS service
# resource "aws_ecs_service" "ecs_service" {
#   name            = "ecs-service"
#   cluster         = aws_ecs_cluster.ecs_cluster.id
#   task_definition = aws_ecs_task_definition.task_definition.arn
#   desired_count   = 1

#   network_configuration {
#     subnets          = [aws_subnet.public1.id]
#     security_groups  = [aws_security_group.ecs_sg.id]
#   }
# }s