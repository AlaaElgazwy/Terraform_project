terraform {
  backend "s3" {
    bucket         = "backend011s3" 
    key            = "global/s3/terraform.tfstate" 
    region         = "us-east-1"
    dynamodb_table = "terraform_state_lock" 
    encrypt        = true
  }
}