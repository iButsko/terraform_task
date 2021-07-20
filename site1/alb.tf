resource "aws_lb" "web_alb" {
  name               = "webserverALB"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public.id, aws_subnet.private.id]
}

resource "aws_lb_target_group" "http" {
  name        = "web-http"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"

  vpc_id = aws_vpc.main.id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  depends_on = [aws_lb.web_alb]

}


resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http.arn
  }
}

resource "aws_lb_listener_rule" "basic-page" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 98
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http.arn
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }

}
resource "aws_lb_listener_rule" "api-page" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 99
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http.arn
  }

  condition {
    path_pattern {
      values = ["/api*"]
    }
  }

}
resource "aws_lb_listener_rule" "service-page" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "ACCESS DENIED. Only through bastion host. please, try use bastion"
      status_code  = 403
    }
  }

  condition {
    path_pattern {
      values = ["/service*"]
    }
  }

}

resource "aws_lb_listener_rule" "bastion-service-page" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 97
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http.arn
  }

  condition {
    path_pattern {
      values = ["/service*"]
    }
  }

  condition {
    source_ip {
      values = ["${aws_eip.bastion.public_ip}/32"]
    }
  }
}

resource "aws_security_group" "alb_sg" {
  name   = "ALB-Allow-All"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}