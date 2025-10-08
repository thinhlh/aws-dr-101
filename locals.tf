locals {
  ami                       = "ami-0e16d075ec2375cf5"
  linux_ami                 = "ami-08982f1c5bf93d976" # Amazon Linux 2023 AMI 2023.8.20250915.0 x86_64 HVM kernel-6.1
  instance_type             = "t2.large"
  replication_instance_type = "t3.medium"
  bucket                    = "jamie-test-tf-bucket"
  vpc_cidr_block            = "10.16.0.0/16"
  tags = {
    "Project" = "drs"
  }
}
