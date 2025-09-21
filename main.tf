provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      "Repository" = "https://github.com/ericdahl/hello-vpc-lattice"
    }
  }
}



data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_region" "current" {}