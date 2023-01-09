####################################################
# ALB Security Group
####################################################
resource "aws_security_group" "alb" {
  name = "alb"
  description = "alb rule based routing"
  vpc_id = aws_vpc.this.id
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "alb"
  }
}

resource "aws_security_group_rule" "alb_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.alb.id
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.alb.id
  cidr_blocks = ["0.0.0.0/0"]
}


####################################################
# ALB instance
####################################################
resource "aws_lb" "this" {
  name = "alb"
  load_balancer_type = "application"
  security_groups = [
    aws_security_group.alb.id
  ]
  subnets = [
    aws_subnet.public_1a.id,
    aws_subnet.public_1c.id
  ]
}

resource "aws_lb_listener" "https" {
  depends_on = [aws_acm_certificate_validation.main]
  load_balancer_arn = aws_lb.this.arn
  port = 443
  protocol = "HTTPS"
  certificate_arn = aws_acm_certificate.main.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.id
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port = 80
  protocol = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port = "443"
      protocol = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}


####################################################
# Route53 record for ALB
####################################################
resource "aws_route53_record" "record" {
  name    = data.aws_route53_zone.main.name
  type    = "A"
  zone_id = data.aws_route53_zone.main.zone_id
  alias {
    evaluate_target_health = true
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
  }
}