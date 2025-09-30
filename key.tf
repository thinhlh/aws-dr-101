data "aws_key_pair" "ec2_window_key" {
  filter {
    name   = "key-name"
    values = ["ec2-window-server-key-pair"]
  }
}

resource "aws_kms_key" "drs_encryption_key" {
  description = "DRS Encryption Key"
  key_usage   = "ENCRYPT_DECRYPT"
  tags = {
    Name = "drs-encryption-key"
  }
}

resource "aws_kms_key" "ebs_encryption_key" {
  description = "EBS Encryption Key"
  key_usage   = "ENCRYPT_DECRYPT"
  tags = {
    Name = "drs-ebs-encryption-key"
  }

}
