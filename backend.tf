terraform {
  backend "s3" {
    bucket = "jamie-test-tf-bucket"
    key    = "dr-101/terraform.tfstate"
    region = "us-east-1"
    # dynamodb_table = "terraform-locks"
    encrypt = true
  }
}
