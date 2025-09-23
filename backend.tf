terraform {
  backend "s3" {
    bucket = "jml-23-09-terraform-state-bucket"
    key    = "dr-101/terraform.tfstate"
    region = "us-east-1"
    # dynamodb_table = "terraform-locks"
    encrypt = true
  }
}
