include "root" {
  path = find_in_parent_folders()
}
include "modules" {
    path = "${dirname(find_in_parent_folders())}/modules/s3.hcl"
}