terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-route53.git//modules/zones?ref=v2.10.2"
}

## Dependencies:

## Variables:
locals {
  global_vars  = read_terragrunt_config(find_in_parent_folders("global.hcl"), {})
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"), {})
  env          = local.env_vars.locals.env
  project_name = local.global_vars.locals.project_name
  domain_name  = lookup(local.global_vars.locals.domain_names, local.env)
  tags = {
    Name = "${local.domain_name}"
    Env = "${local.env}"
  }
}

inputs = {

  zones = {
    "${local.domain_name}" = {
      comment = "Public Domain of ${local.project_name}"
      tags    = local.tags
    }
  }
}
