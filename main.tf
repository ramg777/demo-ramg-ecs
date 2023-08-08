

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
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code  = "200"
      message_body = "OK"
    }
  }

  certificate_arn = "arn:aws:acm:eu-west-2:071148681943:certificate/0b1aa564-2041-4411-851a-5e80c3aefd1e"  # Replace with your ACM certificate ARN
}

resource "aws_lb_target_group" "test-tg" {
  name     = "test-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id  # Replace with your VPC ID

  health_check {
    path     = "/api/emails"
    interval = 120
  }
  
}

resource "aws_lb_listener_rule" "my_listener_rule" {
  listener_arn = aws_lb_listener.https_listener.arn
  priority     = 100

  action {
    type             = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code  = "200"
      message_body = "OK"
    }
  }

  condition {
    path_pattern {
      values = ["/"]
    }

    http_request_method {
      values = ["GET"]
    }

    # source_ip {
    #   values = ["0.0.0.0/0"]  # Adjust as needed
    # }
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