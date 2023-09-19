terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-ec2-instance"
}

dependency "vpc" {
  config_path = "${dirname(find_in_parent_folders())}/demo/ap-southeast-1/vpc"
  mock_outputs = {
      public_subnets = ["subnet-1234", "subnet-5678"]
  }
}


dependency "sg" {
  config_path = "${dirname(find_in_parent_folders())}/demo/ap-southeast-1/sg"
  mock_outputs = {
    ec2_sg = "sg-1234"
  }
}

dependency "key_pair"{
  config_path = "${dirname(find_in_parent_folders())}/demo/ap-southeast-1/key_pair"
  mock_outputs = {
  key_pair = "hblab-test"
  }
}

locals {
  global_vars = read_terragrunt_config(find_in_parent_folders("global.hcl"), {})
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"), {})
  env = local.env_vars.locals.env
}

inputs = {
  name =  lower("${local.env}")

  instance_type          = try(local.global_vars.locals.ec2_settings["${local.env}"]["instance_type"], "t2.nano")
  key_name               = dependency.key_pair.outputs.key_pair
  monitoring             = try(local.global_vars.locals.ec2_settings["${local.env}"]["monitoring"], true)
  vpc_security_group_ids = [dependency.sg.outputs.ec2_sg]
  subnet_id              = dependency.vpc.outputs.public_subnets[0]
  tags = {
    Name = "${local.env}-instance"
    Terraform = "true"
    Environment = "${local.env}"
  }
}
