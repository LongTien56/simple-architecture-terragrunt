terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-cloudfront.git//.?ref=v3.2.1"
}

dependency "ssl" {
  config_path = "${dirname(find_in_parent_folders())}/_env/acm/cloudfront"
}

dependency "bucket" {
  config_path = "${dirname(find_in_parent_folders())}/_env/s3/${local.s3_rname}"
}

dependency "alb" {
  config_path = "${dirname(find_in_parent_folders())}/_env/alb"
}

dependency "log" {
  config_path = "${dirname(find_in_parent_folders())}/_env/s3/logs"
}

## Variables:
locals {
  global_vars  = read_terragrunt_config(find_in_parent_folders("global.hcl"), {})
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"), {})
  env          = local.env_vars.locals.env
#   env_desc     = local.env_vars.locals.env_desc
  name         = lower(basename(get_terragrunt_dir()))
  project_name = local.global_vars.locals.project_name
  domain_name  = try(local.global_vars.locals.domain_names["${local.env}"], "domain.com")
  region       = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  main_region  = try(local.region.locals.region, "ap-southeast-1")

  s3_rname    = try(local.global_vars.locals.cf_settings["s3_rname"], "files")
  s3_patterns = try(local.global_vars.locals.cf_settings["behavior"]["patterns"], ["/api_test/*"])

  enable_cached_backend = try(local.global_vars.locals.cf_settings["enable_cached_backend"], true)
  cached_backend        = try(local.global_vars.locals.cf_settings["cached_backend"], {})

  tags = {
      Name = lower("${local.project_name}-${local.env}-${local.name}")
      Env  = local.env
    }
}

inputs = {
  comment             = "CDN of ${local.project_name} ${local.env}-${local.name}"
  price_class         = try(local.global_vars.locals.cf_settings["${local.env}"]["price_class"], "PriceClass_All")
  is_ipv6_enabled     = try(local.global_vars.locals.cf_settings["ipv6_enabled"], true)
  retain_on_delete    = try(local.global_vars.locals.cf_settings["retain_on_delete"], false)
  wait_for_deployment = try(local.global_vars.locals.cf_settings["wait_for_deployment"], true)
  tags                = local.tags
  aliases             = try(local.global_vars.locals.cf_settings["${local.env}"]["alias"], ["${local.env}.${local.domain_name}"])

  viewer_certificate = {
    acm_certificate_arn      = dependency.ssl.outputs.acm_certificate_arn
    minimum_protocol_version = try(local.global_vars.locals.cf_settings["minimum_protocol_version"], "TLSv1")
    ssl_support_method       = "sni-only"
  }

  ## Origins and behaviors:
  create_origin_access_identity = true
  origin_access_identities = {
    s3_bucket = "CloudFront ${local.project_name}-${local.env}-${local.name} access"
  }

  origin = merge(
    {
      backend = {
        domain_name         = dependency.alb.outputs.lb_dns_name
        connection_attempts = try(local.global_vars.locals.cf_settings["connection_attempts"], 3)
        connection_timeout  = try(local.global_vars.locals.cf_settings["connection_timeout"], 10)
        origin_path         = try(local.global_vars.locals.cf_settings["origin_path"], "")

        custom_header = [
          {
            name  = try(local.global_vars.locals.cf_settings["custom_header_name"], "X-SECURE")
            value = try(local.global_vars.locals.cf_settings["${local.env}"]["custom_header_value"], "X-SECURE-123")
          }
        ]

        custom_origin_config = {
          http_port                = try(local.global_vars.locals.cf_settings["origin_config"]["http_port"], 80)
          https_port               = try(local.global_vars.locals.cf_settings["origin_config"]["https_port"], 443)
          origin_keepalive_timeout = try(local.global_vars.locals.cf_settings["origin_config"]["origin_keepalive_timeout"], 10)
          origin_protocol_policy   = try(local.global_vars.locals.cf_settings["origin_config"]["origin_protocol_policy"], "https-only") # "match-viewer"
          origin_read_timeout      = try(local.global_vars.locals.cf_settings["origin_config"]["origin_read_timeout"], 30)
          origin_ssl_protocols     = try(local.global_vars.locals.cf_settings["origin_config"]["origin_ssl_protocols"], ["TLSv1", "TLSv1.1", "TLSv1.2"])
        }
      }
    },
    { for pattern in local.s3_patterns :
      "${local.project_name}-${local.env}-${replace(trimsuffix(trimprefix(pattern, "/"), "/*"), "/", "-")}" => {
        domain_name = dependency.bucket.outputs.s3_bucket_bucket_domain_name
        origin_path = ""
        s3_origin_config = {
          origin_access_identity = "s3_bucket"
        }
      }
    }
  )



#   default_cache_behavior = local.enable_cached_backend ? local.cached_backend : {}
  default_cache_behavior = local.cached_backend
  ordered_cache_behavior = [for pattern in local.s3_patterns :
    {
      path_pattern           = pattern
      target_origin_id       = "${local.project_name}-${local.env}-${replace(trimsuffix(trimprefix(pattern, "/"), "/*"), "/", "-")}"
      viewer_protocol_policy = try(local.global_vars.locals.cf_settings["behavior"]["viewer_protocol_policy"], "https-only")

      allowed_methods = try(local.global_vars.locals.cf_settings["behavior"]["allowed_methods"], ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"])
      cached_methods  = try(local.global_vars.locals.cf_settings["behavior"]["cached_methods"], ["GET", "HEAD"])
      compress        = try(local.global_vars.locals.cf_settings["behavior"]["compress"], true)
      default_ttl     = try(local.global_vars.locals.cf_settings["behavior"]["default_ttl"], 60)
      max_ttl         = try(local.global_vars.locals.cf_settings["behavior"]["max_ttl"], 31536000)
      min_ttl         = try(local.global_vars.locals.cf_settings["behavior"]["min_ttl"], 0)

      # forwarded_values:
      query_string    = try(local.global_vars.locals.cf_settings["behavior"]["query_string"], true)
      headers         = try(local.global_vars.locals.cf_settings["behavior"]["headers"], ["Access-Control-Request-Headers", "Access-Control-Request-Method", "Origin"])
      cookies_forward = try(local.global_vars.locals.cf_settings["behavior"]["cookies_forward"], "none")

      # functions:
      lambda_function_association = []
      function_association        = []

    }
  ]

  ## Others:
  default_root_object = try(local.global_vars.locals.cf_settings["default_root_object"], "index.html")
  custom_error_response = [
    {
      error_code            = "502"
      response_code         = "502"
      response_page_path    = "/maintain.html"
      error_caching_min_ttl = "300"
    },
    {
      error_code            = "503"
      response_code         = "503"
      response_page_path    = "/maintain.html"
      error_caching_min_ttl = "300"
    },
    {
      error_code            = "504"
      response_code         = "504"
      response_page_path    = "/maintain.html"
      error_caching_min_ttl = "300"
    },
  ]

  logging_config = {
    bucket = dependency.log.outputs.s3_bucket_bucket_domain_name
    prefix = "cloudfront-${local.name}"
  }

  origin_bucket = dependency.bucket.outputs.s3_bucket_id
  aws_region    = dependency.bucket.outputs.s3_bucket_region

}
