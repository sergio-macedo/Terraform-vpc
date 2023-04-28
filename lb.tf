resource "aws_lb_target_group" "sergio-tg" {
  name        = "sergio-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.sergio-vpc.id
  target_type = "instance"
  health_check {
    interval            = 10
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "sergio-listener" {
  load_balancer_arn = aws_lb.sergio-load-balancer.arn
  port              = "80"
  protocol          = "HTTP"
  depends_on        = [aws_lb_target_group.sergio-tg]

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sergio-tg.arn
  }
}

resource "aws_lb" "sergio-load-balancer" {
  name               = "sergio-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb-sg.id]
  subnets            = aws_subnet.public-subnets[*].id

  enable_deletion_protection = false

  tags = {
    Environment = "sergio-lb"
  }
}
#resource "aws_security_group" "instance-sg" {
#  name        = "instance-sg"
#  description = "http access"
#  vpc_id      = aws_vpc.sergio-vpc.id
#
#  ingress {
#    from_port       = 80
#    protocol        = "tcp"
#    to_port         = 80
#    cidr_blocks     = ["10.110.99.0/24"]
#    security_groups = [aws_security_group.lb-sg.id]
#  }
#  egress {
#    from_port   = 0
#    protocol    = "-1"
#    to_port     = 0
#    cidr_blocks = ["0.0.0.0/0"]
#  }
#
#
#}

resource "aws_security_group" "lb-sg" {
  name        = "lb-sg"
  description = "access to the lb"
  vpc_id      = aws_vpc.sergio-vpc.id

}

resource "aws_security_group_rule" "sinbound_ssh" {
  from_port         = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.lb-sg.id
  to_port           = 22
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "sinbound_http" {
  from_port         = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.lb-sg.id
  to_port           = 80
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "soutbound_all" {
  from_port         = 0
  protocol          = -1
  security_group_id = aws_security_group.lb-sg.id
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}


#resource "aws_security_group" "sergio-sg" {
#  name        = "allow_http_access"
#  description = "allow inbound http traffic"
#  vpc_id      = aws_vpc.sergio-vpc.id
#
#
#  ingress {
#
#    description     = "from my ip range"
#    from_port       = "80"
#    to_port         = "80"
#    protocol        = "tcp"
#    cidr_blocks     = ["0.0.0.0/0"]
#  }
#  egress {
#    from_port       = "0"
#    protocol        = "-1"
#    to_port         = "0"
#    cidr_blocks     = ["0.0.0.0/0"]
#  }
#  tags = {
#    "Name" = "sergio-sg"
#  }
#}
#
#resource "aws_security_group" "lb-sg" {
#  name   = "sergio-lb-sg"
#  vpc_id = aws_vpc.sergio-vpc.id
#  ingress {
#    protocol  = -1
#    from_port = 0
#    to_port   = 0
#    security_groups = [aws_security_group.sergio-sg.id]
#
#  }
#
#  egress {
#    from_port   = 0
#    to_port     = 0
#    protocol    = "-1"
#    cidr_blocks = ["0.0.0.0/0"]
#    security_groups = [aws_security_group.sergio-sg.id]
#
#  }
#}
#resource "aws_security_group_rule" "" {
#  from_port         = 0
#  protocol          =
#  security_group_id = aws_security_group.lb-sg.id
#  to_port           = 0
#  type              = ""
#}
/* #Auto Scaling */
resource "aws_autoscaling_group" "sergio-asg" {
  name                      = "sergio-asg"
  desired_capacity          = 2
  max_size                  = 4
  min_size                  = 2
  health_check_type         = "ELB"
  health_check_grace_period = 300
  force_delete              = true
  vpc_zone_identifier       = [for subnet in aws_subnet.private_subnets : subnet.id]
  target_group_arns         = [aws_lb_target_group.sergio-tg.arn]
  launch_template {
    id      = aws_launch_template.ec2-sergio-template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "asg"
    propagate_at_launch = true
  }
}

resource "aws_launch_template" "ec2-sergio-template" {
  name                   = "ec2-sergio-template"
  image_id               = data.aws_ami.amazon_ami.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.sergio-asg-sg.id]
  user_data              = base64encode(file("ec2-user-data.sh"))
}
#resource "aws_launch_configuration" "sergio-lc" {
#  name            = "ec2-asg"
#  image_id        = data.aws_ami.amazon_ami.id
#  instance_type   = "t2.micro"
#  user_data       = file("ec2-user-data.sh")
#  security_groups = [aws_security_group.sergio-asg-sg.id]
#
#  lifecycle {
#    create_before_destroy = true
#  }
#}

resource "aws_autoscaling_attachment" "asg-attach" {
  autoscaling_group_name = aws_autoscaling_group.sergio-asg.id
  lb_target_group_arn    = aws_lb_target_group.sergio-tg.arn
}

resource "aws_security_group" "sergio-asg-sg" {
  name   = "my-asg-sg"
  vpc_id = aws_vpc.sergio-vpc.id
}


resource "aws_security_group_rule" "inbound_ssh" {
  from_port         = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.sergio-asg-sg.id
  to_port           = 22
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "inbound_http" {
  from_port         = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.sergio-asg-sg.id
  to_port           = 80
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "outbound_all" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.sergio-asg-sg.id
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}


#resource "aws_placement_group" "sergio-test" {
#  name     = "test"
#  strategy = "cluster"
#}

