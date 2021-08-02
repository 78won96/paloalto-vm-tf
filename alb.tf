variable "vpc_id"{
  default = "vpc-0d5f2996710314e23"
}

variable "subnet_id"{
  default = ["subnet-025dcbd3150b5b111", "subnet-0431f165acdf120af"]              //public subnet id 
}

resource "aws_security_group" "allow_alb" {
  name        = "allow_alb"
  description = "Allow ALB inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description      = "ALB from VPC"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_alb"
  }
}


resource "aws_lb" "test_alb" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_alb.id]                          //앞의 security gp 리소스 참조 
  subnets            = var.subnet_id
  enable_deletion_protection = false                                              //true 로 할경우 destroy 가 안됨

  tags = {
    Name = "alb"
  }
}

resource "aws_lb_target_group" "test" {
  name     = "tf-example-lb-tg"
  port     = 80
  protocol = "HTTP"
  target_type = "instance"
  vpc_id   = var.vpc_id
  
  health_check {
        enabled             = true
        healthy_threshold   = 3
        interval            = 5
        matcher             = "200"
        path                = "/"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 2
        unhealthy_threshold = 2
    }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.test_alb.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.test.arn                               //lb target gp name 설정
  }
}

resource "aws_lb_target_group_attachment" "paloalto" {
  count = length(data.aws_instances.test.ids)
  target_group_arn = aws_lb_target_group.test.arn
  target_id        = element(data.aws_instances.test.ids, count.index)
  port             = 8080

}

data "aws_instances" "test" {                                                     // instance resource의 Data를 가져옴
  instance_tags = {
    Name = "Paloalto_*"
  }
}