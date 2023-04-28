#output "instance_app-server_public_dns" {
#  value = aws_instance.sergio-ec2.*.private_dns
#}
output "load_balancer_dns_name" {
  value = aws_lb.sergio-load-balancer.dns_name
}

output "asg_name" {
  value = aws_autoscaling_group.sergio-asg.name
}
