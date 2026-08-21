terraform {
  backend "s3" {
    bucket = "tech-challenge-soat16-grupo15"
    key    = "terraform/terraform.tfstate"
    region = "us-east-1"
  }
}