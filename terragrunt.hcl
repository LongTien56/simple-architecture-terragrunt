
locals {
  global_vars  = read_terragrunt_config(find_in_parent_folders("global.hcl", "global.hcl"))
  # account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl", "account.hcl"))
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl", "region.hcl"))
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl", "env.hcl"))

  # Extract the variables we need for easy access
  project_name = local.global_vars.locals.project_name
  # account_id   = local.account_vars.locals.aws_account_id
  aws_region   = local.region_vars.locals.region
}



remote_state {
  backend = "s3"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    encrypt        = true
    bucket         = format("${lower(local.project_name)}-tfstate-%s", get_aws_account_id())
    key            = "${replace(path_relative_to_include(), "_env/", "${local.env_vars.locals.env}/")}/terraform.tfstate"
    region         = try(local.global_vars.locals.state_region, local.aws_region)
    dynamodb_table = "${local.project_name}-terraform-locks"

    skip_metadata_api_check     = true // commented when using with iam_role on ec2
    skip_region_validation      = true
    skip_credentials_validation = true
  }
}

generate "provider" {
  path = "provider.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<EOF
provider "aws" {
    region = "${local.aws_region}"
}
EOF

}