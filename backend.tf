terraform {
  backend "s3" {
    bucket = "zia-bucket-terraform-practise"
    key = "zia-terraform-practise/terraform.tfstate"
    region = "us-east-1"
  }
}