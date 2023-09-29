terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-rds-aurora"
}


locals {
  global_vars = read_terragrunt_config(find_in_parent_folders("global.hcl"), {})
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"), {})
  env = local.env_vars.locals.env
}


dependency "sg" {
  config_path = "${dirname(find_in_parent_folders())}/_env/sg"
  mock_outputs = {
    ec2_sg = "sg-1234"
    rds_sg = "sg-3456"
  }
}

dependency "vpc" {
  config_path = "${dirname(find_in_parent_folders())}/_env/vpc"
  mock_outputs = {
      public_subnets = ["subnet-1234", "subnet-5678"]
      vpc_id = "vpc-1234"
      private_subnets = ["subnet-2345", "subnet-898"]
  }
}



inputs = {
  create_security_group = false
  name           = "${local.env}-database"
  engine         = local.global_vars.locals.rds_settings.engine
  engine_version = local.global_vars.locals.rds_settings.engine_version
  vpc_id         = dependency.vpc.outputs.vpc_id
  security_group_id = dependency.sg.outputs.rds_sg
  instance_class = local.global_vars.locals.rds_settings["${local.env}"].instance_class
  instances = local.global_vars.locals.rds_settings["${local.env}"].instances
  storage_encrypted   = local.global_vars.locals.rds_settings["${local.env}"].storage_encrypted
  apply_immediately   = local.global_vars.locals.rds_settings["${local.env}"].apply_immediately
  monitoring_interval = local.global_vars.locals.rds_settings["${local.env}"].monitoring_interval
  deletion_protection = local.global_vars.locals.rds_settings["${local.env}"].deletion_protection
  skip_final_snapshot = local.global_vars.locals.rds_settings["${local.env}"].skip_final_snapshot
  enabled_cloudwatch_logs_exports = local.global_vars.locals.rds_settings["${local.env}"].enabled_cloudwatch_logs_exports
  create_db_subnet_group = local.global_vars.locals.rds_settings["${local.env}"].create_db_subnet_group
  subnets = [ for pvsubnet in dependency.vpc.outputs.private_subnets[*] : pvsubnet ]
  master_username = local.global_vars.locals.rds_settings["${local.env}"].master_username
  tags = {
    Environment = "${local.env}"
    Terraform   = "true"
  }
}