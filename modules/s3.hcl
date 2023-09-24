terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-s3-bucket"
}


locals {
  global_vars = read_terragrunt_config(find_in_parent_folders("global.hcl"), {})
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"), {})
  env = local.env_vars.locals.env
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"), {})
  region = local.region_vars.locals.region
  name = lower("tienll-${local.env}-${basename(get_terragrunt_dir())}-${local.region}")
}


inputs = {
    force_destroy = true
    bucket = "${local.name}"
    # acl = "private"
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true

    tags = {
        Name = "${local.name}"
        En = "${local.env}"
    }
}