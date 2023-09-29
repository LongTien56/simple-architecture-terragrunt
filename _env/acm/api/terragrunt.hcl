include "root" {
  path = find_in_parent_folders()
}

include "modules" {
  path = "${dirname(find_in_parent_folders())}/modules/acm.hcl"
}

## Variables:
inputs = {}
