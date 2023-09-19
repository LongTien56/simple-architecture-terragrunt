include "root" {
  path = find_in_parent_folders()
}
include "modules" {
    path = "${dirname(find_in_parent_folders())}/modules/${basename(get_terragrunt_dir())}.hcl"
}