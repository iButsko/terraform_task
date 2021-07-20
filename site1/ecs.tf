resource "aws_ecs_cluster" "HA-cluster" {
  name = "ecs-cluster"

}

#Elastic Container Service(ECS) Security Group
resource "aws_security_group" "ecs_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_ecs_service" "webserver" {
  name            = "webserver"
  cluster         = aws_ecs_cluster.HA-cluster.id
  task_definition = aws_ecs_task_definition.task_definition.arn
  desired_count   = 2

  network_configuration {
    subnets = [
      aws_subnet.private.id,
      aws_subnet.public.id
    ]

    security_groups = [aws_security_group.ecs_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.http.arn
    container_name   = "webserver"
    container_port   = 80
  }

}

resource "aws_launch_configuration" "ecs_launch_config" {
  name_prefix                 = "ecs-launch-config"
  image_id                    = "ami-0d430558cf034b341"
  instance_type               = "t2.small"
  iam_instance_profile        = aws_iam_instance_profile.ecs_agent.name
  associate_public_ip_address = true
  key_name                    = "webserver1"
  user_data                   = "#!/bin/bash\necho ECS_CLUSTER=ecs-cluster >> /etc/ecs/ecs.config"
  security_groups             = ["${aws_security_group.ecs_sg.id}"]
}

resource "aws_autoscaling_group" "ecs_ec2_asg" {
  name                      = "ha-ecs-asg1"
  launch_configuration      = aws_launch_configuration.ecs_launch_config.name
  vpc_zone_identifier       = [aws_subnet.private.id, aws_subnet.public.id]
  min_size                  = 1
  max_size                  = 6
  health_check_grace_period = 120 
  health_check_type         = "EC2"
  desired_capacity          = 2
  force_delete              = false 

  tag {
    key                 = "name"
    value               = "ecs-cluster"
    propagate_at_launch = true
  }
}

resource "aws_ecs_task_definition" "task_definition" {
  family       = "webserver"
  network_mode = "awsvpc" 

  container_definitions = jsonencode([
    {
      name      = "webserver"
      image     = var.ecr_image
      cpu       = 10
      memory    = 128
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}


#ECS iam role & role policy
resource "aws_iam_role" "ecs_agent" {
  name = "ecs-agent"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_agent" {
  role       = aws_iam_role.ecs_agent.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"

}

resource "aws_iam_instance_profile" "ecs_agent" {
  name = "ecs-agent"
  role = aws_iam_role.ecs_agent.name
}

