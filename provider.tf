provider "aws" {
  profile = "root"
  region  = "ap-northeast-2"
}

terraform {
  backend "s3" {
    bucket  = "dk-state-bucket"
    key     = "ecs"
    region  = "ap-northeast-2"
    profile = "root"
  }
}
