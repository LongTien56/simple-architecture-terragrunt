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
    config_path = "${dirname(find_in_parent_folders())}/_env/vpc"
    mock_outputs = {
        vpc_id = "vpc-1234"
        public_subnets = ["subnet-1234", "subnet-5678"]
    }
}


dependency "sg" {
  config_path = "${dirname(find_in_parent_folders())}/_env/sg"
  mock_outputs = {
    alb_sg = "sg-3456"
  }
}

dependency "ec2"{
  config_path = "${dirname(find_in_parent_folders())}/_env/ec2"
  mock_outputs = {
    id = "ec2-1234"
  }
}

dependency "s3_logs" {
  config_path ="${dirname(find_in_parent_folders())}/_env/s3/logs"
  mock_outputs = {
    s3_bucket_id = "logs_sample_bucket"
  }
}

dependency "ssl" {
  config_path = "${dirname(find_in_parent_folders())}/_env/acm/api"
  mock_outputs = {
    acm_certificate_arn = "arn:aws:iam::123456789012:server-certificate/test_cert-123456789012"
  }
}

inputs = {
  create_security_group = false
  load_balancer_type = local.global_vars.locals.alb_settings["load_balancer_type"]

  vpc_id             = dependency.vpc.outputs.vpc_id
  subnets            = [ for subnet in dependency.vpc.outputs.public_subnets : subnet ]
  security_groups    = [dependency.sg.outputs.alb_sg]

  access_logs = {
    bucket = dependency.s3_logs.outputs.s3_bucket_id
  }

  target_groups = [
    {
      name             = lower("${local.global_vars.locals.project_name}-${local.env}-${local.name}")
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = try(local.global_vars.locals.elb_settings["target_type"], "instance")
      health_check = {
        interval            = 10
        path                = try(local.global_vars.locals.elb_settings["health_check_path"], "/")
        matcher             = try(local.global_vars.locals.elb_settings["matcher"], "200")
        timeout             = 5
        healthy_threshold   = 3
        unhealthy_threshold = 2
      }
      deregistration_delay = try(local.global_vars.locals.elb_settings["deregistration_delay"], "300")
    },
  ]

  https_listeners = [
    {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = dependency.ssl.outputs.acm_certificate_arn
      action_type     = "fixed-response"
      fixed_response = {
        content_type = "text/html"
        message_body = "Access denied"
        status_code  = "403"
      }
    }
  ]
  
  http_tcp_listeners = [
      {
        port               = 80
        protocol           = "HTTP"
        # target_group_index = 0
        action_type = "redirect"
        redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
        host     = "#{host}"
        path     = "/#{path}"
        query    = "#{query}"
        }
      }
  ]

  # tags = {
  #     Environment = "${local.env}}"
  # }    
}

