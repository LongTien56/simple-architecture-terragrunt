# include "root" {
#   path = find_in_parent_folders()
# }

include "modules" {
    path = "${dirname(find_in_parent_folders())}/modules/acm.hcl"
}

#Dependencies:
dependencies {
  paths = [
    "${dirname(find_in_parent_folders())}/_env/acm/api",
  ]
}

## Variables:
locals {
  global_vars = read_terragrunt_config(find_in_parent_folders("global.hcl"), {})
  env_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"), {})
  env         = local.env_vars.locals.env
  region = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  aws_region  = "us-east-1"
}

inputs = {
  # provider = us_east
  wait_for_validation    = false
  create_route53_records = false
  validate_certificate   = false
  providers = {
    region = "us-east-1"
  }
}
