output "load_balancer_dns_name" {
  value = aws_lb.sergio-load-balancer.dns_name
}
output "asg_name" {
  value = aws_autoscaling_group.sergio-asg.name
}
