# Variables for AWS Windows EC2 with DRS POC

variable "primary_region" {
  description = "Primary AWS region"
  type        = string
  default     = "us-east-1"
}

variable "secondary_region" {
  description = "Secondary AWS region for disaster recovery"
  type        = string
  default     = "us-west-2"
}

variable "instance_type" {
  description = "EC2 instance type for Windows servers"
  type        = string
  default     = "t3.medium"
}

variable "key_pair_name" {
  description = "EC2 Key Pair name for Windows instances"
  type        = string
  default     = "aws-dr-101-key"
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "aws-dr-101"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "poc"
}

variable "vpc_cidr_primary" {
  description = "CIDR block for primary VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_cidr_secondary" {
  description = "CIDR block for secondary VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the instances"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Note: Restrict this in production
}

variable "enable_drs" {
  description = "Enable AWS Elastic Disaster Recovery"
  type        = bool
  default     = true
}

variable "replication_instance_type" {
  description = "Instance type for DRS replication servers"
  type        = string
  default     = "t3.small"
}