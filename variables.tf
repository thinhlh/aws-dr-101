variable "aws_region" {
  default = "us-east-1"
}

variable "key_pair_name" {
  description = "Key pair name"
  type        = string
}

variable "azs" {
  description = "List of availability zones"
  type        = list(string)
  # default     = ["us-east-1a", "us-east-1b"]
  default = ["us-east-1a"]
}
