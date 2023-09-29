include "root" {
  path = find_in_parent_folders()
}

include "modules" {
  path = "${dirname(find_in_parent_folders())}/modules/cloudfront.hcl"
}

dependency "dns" {
  config_path = "${dirname(find_in_parent_folders())}/_env/route53/public"
}

dependency "alb" {
  config_path = "${dirname(find_in_parent_folders())}/_env/alb"
}

## Variables:
locals {
  global_vars = read_terragrunt_config(find_in_parent_folders("global.hcl"), {})
  env_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"), {})
  domain_name = try(local.global_vars.locals.domain_names["${local.env}"], "${local.env}.local")
  env         = local.env_vars.locals.env
  region      = read_terragrunt_config(find_in_parent_folders("region.hcl"))
#   main_region = local.region.locals.region
  main_region = "us-east-1"
  name        = basename(get_terragrunt_dir())

  env_check   = get_env("ENV", "dev")
  folder_name = local.env_check == "dev" ? "env" : "common"
}
inputs = {
  ### create route53 record point to CF DNS
  domain_name  = lower(local.domain_name)
  zone_id      = dependency.dns.outputs.route53_zone_zone_id
  lb_zone_id   = dependency.alb.outputs.lb_zone_id
  public_hosts = ["dev"]
}

