terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc"
}


locals {
  global_vars = read_terragrunt_config(find_in_parent_folders("global.hcl"), {})
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"), {})
  env = local.env_vars.locals.env
}

inputs = {
  env             = upper(local.env_vars.locals.env)
  azs             = local.global_vars.locals.vpc_settings.azs
  private_subnets = local.global_vars.locals.vpc_settings.private_subnets
  public_subnets  = local.global_vars.locals.vpc_settings.public_subnets

  enable_nat_gateway = try(local.global_vars.locals.vpc_settings["${local.env}"]["enable_nat_gateway"], true)
  single_nat_gateway = try(local.global_vars.locals.vpc_settings["${local.env}"]["single_nat_gateway"], true)

  tags = {
    Name = "${local.env}-vpc"
    Terraform = "true"
    Environment = "${local.env}"
  }
}