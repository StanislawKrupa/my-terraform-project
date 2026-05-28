terraform {
  backend "s3" {
    bucket         = "terraform254977" # Zmień na własny
    key            = "order-pipeline/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}