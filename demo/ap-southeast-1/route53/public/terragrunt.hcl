include "root" {
  path = find_in_parent_folders()
}
include "modules" {
    path = "${dirname(find_in_parent_folders())}/modules/${basename(dirname("${get_terragrunt_dir()}/../.."))}.hcl"
}


locals {
    env_check = get_env("ENV", "dev")
}

inputs = {
    # create = local.env_check == "dev" ? false : true
    create = true
}