terraform {
  backend "s3" {
    bucket         = "my-tf-state-bucket"
    key            = "day-c/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "tf-state-locks"
    encrypt        = true
  }
}
