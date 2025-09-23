output "instance_ids" {
  value = [for i in aws_instance.windows : i.id]
}

output "instance_ips" {
  value = [for i in aws_instance.windows : i.private_ip]
}

output "vpc_endpoint_ids" {
  value = [
    aws_vpc_endpoint.ssm.id,
    aws_vpc_endpoint.ssmmessages.id,
    aws_vpc_endpoint.ec2messages.id
  ]
}
