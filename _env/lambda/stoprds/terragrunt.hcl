include "root" {
  path = find_in_parent_folders()
}

include "modules" {
  path = "${dirname(find_in_parent_folders())}/modules/lambda.hcl"
}

## Variables:
locals {
  global_vars  = read_terragrunt_config(find_in_parent_folders("global.hcl"), {})
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"), {})
  env          = local.env_vars.locals.env
  env_check    = get_env("ENV", "dev")
  aws_region   = local.region_vars.locals.region
  is_scheduled = try(local.global_vars.locals.rds_settings["${local.env}"]["is_scheduled"], false)
}

inputs = {
  ## No scheduled in prod env
  create = (local.env_check == "prod" && local.is_scheduled == false) ? false : true

  ## IAM Role:
  policy_json = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowLambdaStopStartRDS",
      "Effect": "Allow",
      "Action": [
        "rds:DescribeDBClusterParameters",
        "rds:StartDBCluster",
        "rds:StopDBCluster",
        "rds:DescribeDBEngineVersions",
        "rds:DescribeGlobalClusters",
        "rds:DescribePendingMaintenanceActions",
        "rds:DescribeDBLogFiles",
        "rds:StopDBInstance",
        "rds:StartDBInstance",
        "rds:DescribeReservedDBInstancesOfferings",
        "rds:DescribeReservedDBInstances",
        "rds:ListTagsForResource",
        "rds:DescribeValidDBInstanceModifications",
        "rds:DescribeDBInstances",
        "rds:DescribeSourceRegions",
        "rds:DescribeDBClusterEndpoints",
        "rds:DescribeDBClusters",
        "rds:DescribeDBClusterParameterGroups",
        "rds:DescribeOptionGroups"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF

  ## Schedule:
  schedule_expression = "cron(0 15 ? * * *)"

  ## Vars:
  environment_variables = {
    REGION = local.aws_region
    KEY    = try(local.global_vars.locals.rds_settings["schedule_key"], "SCHEDULED")
    VALUE  = try(local.global_vars.locals.rds_settings["schedule_value"], "True")
  }
}
