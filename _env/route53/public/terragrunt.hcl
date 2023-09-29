include "root" {
  path = find_in_parent_folders()
}
include "modules" {
    path = "${dirname(find_in_parent_folders())}/modules/${basename(dirname("${get_terragrunt_dir()}/../.."))}.hcl"
}


locals {
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"), {})
  env = local.env_vars.locals.env
}

inputs = {
    # create = local.env_check == "dev" ? false : true
    create = true
}