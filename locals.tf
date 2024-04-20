locals {
  _vpc = data.terraform_remote_state.network.outputs.vpc.vpc

  vpc_id            = local._vpc.vpc_id
  webserver_subnets = local._vpc.webserver_subnets
  was_subnets       = local._vpc.was_subnets
  db_subnets        = local._vpc.db_subnets
  region            = local._vpc.regions
}
