terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-lambda.git//.?ref=v6.0.0"
}

## Variables:
locals {
  global_vars  = read_terragrunt_config(find_in_parent_folders("global.hcl"), {})
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl"), {})
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"), {})
  env          = local.env_vars.locals.env
  aws_region   = local.region_vars.locals.region
  name         = basename(get_terragrunt_dir())
  project_name = local.global_vars.locals.project_name
  name_prefix  = "${local.project_name}-${local.env}"
  runtime      = try(local.global_vars.locals.lambda_settings[local.name]["runtime"], "python3.7")
  index_file   = length(regexall("python", local.runtime)) > 0 ? "index.py" : "index.js"

  tags ={
      Name = lower("${local.name_prefix}-${local.name}")
      Env  = local.env
    }
}

inputs = {
  function_name = "${local.name_prefix}-${local.name}"
  description   = "${local.name_prefix}-${local.name} function"
  handler       = try(local.global_vars.locals.lambda_settings[local.name]["handler"], "index.lambda_handler")
  runtime       = local.runtime
  memory_size   = try(local.global_vars.locals.lambda_settings[local.name]["memory_size"], "128")
  timeout       = try(local.global_vars.locals.lambda_settings[local.name]["timeout"], "5")
  tags          = local.tags
  publish       = true

  source_path = [
    "${dirname(find_in_parent_folders())}/templates/lambda/${local.name}/${local.index_file}"
  ]

  create_role        = true
  role_name          = lower("${local.name_prefix}-lambda-${local.name}")
  lambda_at_edge     = false
  attach_policy_json = true
  # policy_json      = <<EOF #

  ## Schedule:
  schedule_name        = "${local.name_prefix}-lambda-${local.name}"
  schedule_description = "lambda ${local.name}"
  schedule_expression  = "cron(0 17 ? * * *)"

  ## Variables:
  environment_variables = {
    TZ = try(local.global_vars.locals.time_zone, "Asia/Tokyo")
  }

}
