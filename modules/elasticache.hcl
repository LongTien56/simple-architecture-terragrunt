terraform {
  source = "github.com/cloudposse/terraform-aws-elasticache-redis"
}

dependency "sg" {
  config_path = "${dirname(find_in_parent_folders())}/_env/sg"
}

dependency "vpc" {
  config_path = "${dirname(find_in_parent_folders())}/_env/vpc"
}

dependency "route53" {
  config_path = "${dirname(find_in_parent_folders())}/_env/route53/private"
}

## Variables:
locals {
  global_vars  = read_terragrunt_config(find_in_parent_folders("global.hcl"), {})
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl"), {})
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"), {})
  env          = local.env_vars.locals.env
  aws_region   = local.region_vars.locals.region
  project_name = local.global_vars.locals.project_name
  name         = lower("${local.project_name}-${local.env}-${basename(get_terragrunt_dir())}")
  domain_local = try(local.global_vars.locals.domain_locals["${local.env}"], "${local.env}.local")

  env_check   = get_env("ENV", "dev")
  folder_name = local.env_check == "dev" ? "env" : "common"

  tags = {
      Env  = local.env
      Type = local.name
    }
}

inputs = {
  name              = local.name
  vpc_id            = dependency.vpc.outputs.vpc_id
  subnets           = dependency.vpc.outputs.private_subnets
  subnet_group_name = local.name
  tags              = local.tags

  use_existing_security_groups = true
  existing_security_groups     = [dependency.sg.outputs.elasticache_sg]

  instance_type              = try(local.global_vars.locals.elasticache_settings["${local.env}"]["instance_type"], "cache.t3.micro")
  cluster_size               = try(local.global_vars.locals.elasticache_settings["${local.env}"]["cluster_size"], "1")
  family                     = try(local.global_vars.locals.elasticache_settings["family"], "redis6.x")
  engine_version             = try(local.global_vars.locals.elasticache_settings["engine_version"], "6.x")
  transit_encryption_enabled = false

  automatic_failover_enabled           = try(local.global_vars.locals.elasticache_settings["${local.env}"]["automatic_failover_enabled"], false)
  cluster_mode_num_node_groups         = try(local.global_vars.locals.elasticache_settings["${local.env}"]["cluster_mode_num_node_groups"], "1")
  cluster_mode_replicas_per_node_group = try(local.global_vars.locals.elasticache_settings["${local.env}"]["cluster_mode_replicas_per_node_group"], "1")

#   snapshot_window          = local.global_vars.locals.snapshot_window
#   maintenance_window       = local.global_vars.locals.maintenance_window
#   snapshot_retention_limit = local.global_vars.locals.retention_days

  dns_subdomain      = "${local.env}-redis-writer"
  availability_zones = dependency.vpc.outputs.azs
  zone_id            = [dependency.route53.outputs.route53_zone_zone_id["${local.domain_local}"]]

}
