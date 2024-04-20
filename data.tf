data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket  = "dk-state-bucket"
    key     = "network"
    region  = "ap-northeast-2"
    profile = "root"
  }
}
