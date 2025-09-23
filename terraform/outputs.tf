# Outputs for AWS Windows EC2 with DRS POC

output "primary_instance_id" {
  description = "ID of the primary Windows EC2 instance"
  value       = aws_instance.windows_primary.id
}

output "primary_instance_public_ip" {
  description = "Public IP address of the primary Windows EC2 instance"
  value       = aws_eip.primary.public_ip
}

output "primary_instance_private_ip" {
  description = "Private IP address of the primary Windows EC2 instance"
  value       = aws_instance.windows_primary.private_ip
}

output "secondary_instance_id" {
  description = "ID of the secondary Windows EC2 instance"
  value       = aws_instance.windows_secondary.id
}

output "secondary_instance_public_ip" {
  description = "Public IP address of the secondary Windows EC2 instance"
  value       = aws_eip.secondary.public_ip
}

output "secondary_instance_private_ip" {
  description = "Private IP address of the secondary Windows EC2 instance"
  value       = aws_instance.windows_secondary.private_ip
}

output "primary_vpc_id" {
  description = "ID of the primary VPC"
  value       = aws_vpc.primary.id
}

output "secondary_vpc_id" {
  description = "ID of the secondary VPC"
  value       = aws_vpc.secondary.id
}

output "web_application_urls" {
  description = "URLs to access the web applications"
  value = {
    primary   = "http://${aws_eip.primary.public_ip}"
    secondary = "http://${aws_eip.secondary.public_ip}"
  }
}

output "rdp_access_info" {
  description = "Information for RDP access to Windows instances"
  value = {
    primary_ip   = aws_eip.primary.public_ip
    secondary_ip = aws_eip.secondary.public_ip
    port         = 3389
    note         = "Use EC2 Instance Connect or your key pair to get the Administrator password"
  }
}

output "drs_configuration_template_id" {
  description = "ID of the DRS replication configuration template"
  value       = var.enable_drs ? aws_drs_replication_configuration_template.main[0].id : null
}

output "drs_launch_configuration_note" {
  description = "Note about DRS launch configuration template"
  value       = var.enable_drs ? local.drs_launch_config_note : null
}

output "kms_key_id" {
  description = "ID of the KMS key for DRS encryption"
  value       = aws_kms_key.drs.id
}

output "kms_key_alias" {
  description = "Alias of the KMS key for DRS encryption"
  value       = aws_kms_alias.drs.name
}

output "iam_instance_profile_name" {
  description = "Name of the IAM instance profile"
  value       = aws_iam_instance_profile.ec2_instance_profile.name
}

output "security_group_ids" {
  description = "Security group IDs"
  value = {
    primary_windows   = aws_security_group.windows_primary.id
    secondary_windows = aws_security_group.windows_secondary.id
    drs_replication   = aws_security_group.drs_replication.id
  }
}

output "deployment_info" {
  description = "Deployment summary and next steps"
  value = {
    primary_region    = var.primary_region
    secondary_region  = var.secondary_region
    primary_web_url   = "http://${aws_eip.primary.public_ip}"
    secondary_web_url = "http://${aws_eip.secondary.public_ip}"
    dr_enabled        = var.enable_drs
    next_steps = [
      "1. Connect to instances via RDP using the public IPs",
      "2. Install DRS agent on the primary instance",
      "3. Configure replication in DRS console",
      "4. Test failover procedures",
      "5. Monitor replication status in CloudWatch"
    ]
  }
}