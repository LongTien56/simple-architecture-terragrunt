terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-acm.git//.?ref=v4.3.2"
}

## Dependencies

dependency "dns" {
  config_path = "${dirname(find_in_parent_folders())}/demo/ap-southeast-1/route53/public"
}

## Variables:
locals {
  global_vars = read_terragrunt_config(find_in_parent_folders("global.hcl"), {})
  env_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"), {})
  env         = local.env_vars.locals.env
  domain_name = "${lookup(local.global_vars.locals.domain_names, local.env)}"
  root_domain = local.global_vars.locals.root_domain
  env_check   = get_env("ENV", "dev")
  tags = {
    Name = "${local.domain_name}"
    Env = "${local.env}"
  }
}

inputs = {
  domain_name = local.domain_name

  subject_alternative_names = [
    "*.${local.domain_name}"
  ]

  wait_for_validation    = true
  validate_certificate   = true
  create_route53_records = true
  zone_id                = try(dependency.dns.outputs.route53_zone_zone_id["${local.domain_name}"], "")
  tags                   = local.tags

  validation_allow_overwrite_records = false
}
