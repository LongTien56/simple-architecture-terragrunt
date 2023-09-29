include "root" {
  path = find_in_parent_folders()
}
include "modules" {
    path = "${dirname(find_in_parent_folders())}/modules/route53.hcl"
}

dependency "vpc" {
  config_path = "${dirname(find_in_parent_folders())}/_env/vpc"
  mock_outputs = {
      vpc_id = ["vpc-1234"]
  }
}

locals {
  global_vars = read_terragrunt_config(find_in_parent_folders("global.hcl"), {})
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"), {})
  env = local.env_vars.locals.env
  domain_name  = try(local.global_vars.locals.domain_locals["${local.env}"], "${local.env}.local")
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"), {})
  region = local.region_vars.locals.region
  project_name = local.global_vars.locals.project_name
  tags = {
    Name = "${local.domain_name}"
    Env = "${local.env}"
  }
}

inputs = {
  # route53 in common use for stage/prod env
#   create = local.env_check == "dev" ? false : true
  create = true
  zones = {
    "${local.domain_name}" = {
      comment = "Private Domain of ${local.project_name}"
      vpc = [
        {
          vpc_id     = dependency.vpc.outputs.vpc_id
          vpc_region = local.region
        },
      ]
      tags = local.tags
    }
  }
}
