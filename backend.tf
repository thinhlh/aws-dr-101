terraform {
  backend "s3" {
    key    = "dr-101/terraform.tfstate"
    region = "us-east-1"
    # dynamodb_table = "terraform-locks"
    encrypt = true
  }
}
