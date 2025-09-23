# Required for private subnet SSM communication
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.main_vpc.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for s in aws_subnet.project_subnet_private_us_east_1 : s.id]
  security_group_ids  = [aws_security_group.windows_sg.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = aws_vpc.main_vpc.id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for s in aws_subnet.project_subnet_private_us_east_1 : s.id]
  security_group_ids  = [aws_security_group.windows_sg.id]
  private_dns_enabled = true

}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = aws_vpc.main_vpc.id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for s in aws_subnet.project_subnet_private_us_east_1 : s.id]
  security_group_ids  = [aws_security_group.windows_sg.id]
  private_dns_enabled = true

}
