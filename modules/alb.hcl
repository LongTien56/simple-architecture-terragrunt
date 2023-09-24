terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-alb"
}

# include "root" {
#   path = find_in_parent_folders()
# }


locals {
  global_vars = read_terragrunt_config(find_in_parent_folders("global.hcl"), {})
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"), {})
  env = local.env_vars.locals.env
}

dependency "vpc" {
    config_path = "${dirname(find_in_parent_folders())}/demo/ap-southeast-1/vpc"
    mock_outputs = {
        vpc_id = "vpc-1234"
        public_subnets = ["subnet-1234", "subnet-5678"]
    }
}


dependency "sg" {
  config_path = "${dirname(find_in_parent_folders())}/demo/ap-southeast-1/sg"
  mock_outputs = {
    alb_sg = "sg-3456"
  }
}

dependency "ec2"{
  config_path = "${dirname(find_in_parent_folders())}/demo/ap-southeast-1/ec2"
  mock_outputs = {
    id = "ec2-1234"
  }
}

dependency "s3_logs" {
  config_path ="${dirname(find_in_parent_folders())}/demo/ap-southeast-1/s3/logs"
  mock_outputs = {
    s3_bucket_id = "logs_sample_bucket"
  }
}

inputs = {
  create_security_group = false
  name = local.global_vars.locals.alb_settings["name"]

  load_balancer_type = local.global_vars.locals.alb_settings["load_balancer_type"]

  vpc_id             = dependency.vpc.outputs.vpc_id
  subnets            = [ for subnet in dependency.vpc.outputs.public_subnets : subnet ]
  security_groups    = [dependency.sg.outputs.alb_sg]

  access_logs = {
    bucket = dependency.s3_logs.outputs.s3_bucket_id
  }

  target_groups = [
    {
      name_prefix      = "pref-"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
      targets = {
        my_target = {
          target_id = dependency.ec2.outputs.id
          port = 80
        }
      }
    }
  ]

#   https_listeners = [
#     {
#       port               = 443
#       protocol           = "HTTPS"
#       certificate_arn    = "arn:aws:iam::123456789012:server-certificate/test_cert-123456789012"
#       target_group_index = 0
#     }
#   ]

  http_tcp_listeners = local.global_vars.locals.alb_settings["http_tcp_listeners"]

  # tags = {
  #     Environment = "${local.env}}"
  # }    
}

