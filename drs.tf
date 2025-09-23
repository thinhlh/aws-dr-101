resource "aws_drs_replication_configuration_template" "project_drs_replication_config_template" {
  associate_default_security_group        = false
  bandwidth_throttling                    = 10000
  create_public_ip                        = false
  data_plane_routing                      = "PRIVATE_IP"
  default_large_staging_disk_type         = "GP3"
  ebs_encryption                          = "DEFAULT"
  ebs_encryption_key_arn                  = aws_kms_key.drs_encryption_key.arn
  replication_server_instance_type        = local.replication_instance_type
  replication_servers_security_groups_ids = [aws_security_group.replication_sg.id]
  staging_area_subnet_id                  = aws_subnet.project_subnet_private_us_east_1[var.azs[1]].id
  use_dedicated_replication_server        = false

  staging_area_tags = {
    Project = "drs"
  }

  pit_policy {
    enabled            = true
    units              = "MINUTE"
    interval           = 1
    retention_duration = 10080
  }

  tags = {
    Name = "drs-replication-configuration-template"
  }
}
