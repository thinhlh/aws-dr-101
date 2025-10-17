output "instance_ids" {
  value = {
    # windows = aws_instance.windows.id
    linux = aws_instance.linux.id
  }
}

output "vpc_endpoint_ids" {
  value = [
    aws_vpc_endpoint.ssm.id,
    aws_vpc_endpoint.ssmmessages.id,
    aws_vpc_endpoint.ec2messages.id
  ]
}

output "subnet_cidrs" {
  value = {
    for az in var.azs : az => {
      private_cidr = aws_subnet.project_subnet_private_us_east_1[az].cidr_block
      public_cidr  = aws_subnet.project_subnet_public_us_east_1[az].cidr_block
    }
  }
}

# output "window_source_server_id" {
#   description = "The Source Server ID in AWS DRS"
#   value       = data.external.drs_source_servers_id.result
# }

# output "linux_source_server_id" {
#   description = "The Source Server ID in AWS DRS"
#   value       = data.external.drs_linux_source_server_id.result
# }
