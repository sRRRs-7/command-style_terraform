variable "region" {
  type        = string
  description = "aws region"
  default     = "ap-northeast-1"
}

provider "aws" {
  region = var.region
}

terraform {
  required_version = "1.3.6"
  # backend "s3" {
  #   bucket = "<s3 bucket>"
  #   key = "terraform tfstate"
  #   region = "ap-northeast-1"
  # }
}