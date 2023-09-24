locals {
    project_name = "tienll"


    vpc_settings = {
        azs             = ["ap-southeast-1a", "ap-southeast-1b"]
        private_subnets = ["10.0.0.0/19", "10.0.32.0/19"]
        public_subnets  = ["10.0.64.0/19", "10.0.96.0/19"]
        dev = {


            enable_nat_gateway = true
            single_nat_gateway = true
        },

        staging = {

            enable_nat_gateway = false
            single_nat_gateway = false
        },

        production = {

            enable_nat_gateway = true
            single_nat_gateway = true
        },
    }

    ec2_settings = {
        dev = { 
            instance_type          = "t2.micro"
            monitoring             = false
        },

        staging = { 
                instance_type          = "t2.small"
                monitoring             = false
        },

        production = { 
                instance_type          = "t3.medium"
                monitoring             = true
        },
    }

    alb_settings = {
        name = "my-alb"

        load_balancer_type = "application"

        #   https_listeners = [
        #     {
        #       port               = 443
        #       protocol           = "HTTPS"
        #       certificate_arn    = "arn:aws:iam::123456789012:server-certificate/test_cert-123456789012"
        #       target_group_index = 0
        #     }
        #   ]

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
    }


    rds_settings = {
        engine = "aurora-mysql"
        engine_version = "8.0.mysql_aurora.3.04.0"

        dev = {
            instance_class = "db.t3.medium"
            instances = {
                # one = {}
            }
            master_username = "tienll"
            create_db_subnet_group = true
            storage_encrypted   = false
            apply_immediately   = true
            monitoring_interval = 10
            deletion_protection = false
            skip_final_snapshot = true
            enabled_cloudwatch_logs_exports = ["general"]
        },

        production = {
            instance_class = "db.t3.large"
            instances = {
                one = {}
            }
            master_username = "tienll"
            create_db_subnet_group = true
            storage_encrypted   = true
            apply_immediately   = false
            monitoring_interval = 10
            deletion_protection = true
            skip_final_snapshot = false
            enabled_cloudwatch_logs_exports = ["mysql"]
        },        

    }


  eb_settings = {
    region = "ap-southeast-1"
    solution_stack_name            = "64bit Amazon Linux 2 v3.5.4 running PHP 8.0"
    matcher_http_code              = "200,404"
    healthcheck_url                = "/"
    root_volume_size               = "20"
    autoscale_lower_bound          = 20
    autoscale_upper_bound          = 50
    autoscale_lower_increment      = -1
    autoscale_upper_increment      = 2
    loadbalancer_type              = "application"
    # loadbalancer_ssl_policy        = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
    rolling_update_enabled         = false
    # logs_retention_in_days         = 30
    # enable_stream_logs             = true
    # enable_log_publication_control = true
    loadbalancer_is_shared = true


    scheduled_actions = [
      {
        name            = "Start"
        minsize         = 1
        maxsize         = 1
        desiredcapacity = 1
        starttime       = ""
        endtime         = ""
        recurrence      = "30 00 * * 1-5"
        suspend         = false
      },
      {
        name            = "Stop"
        minsize         = 0
        maxsize         = 0
        desiredcapacity = 0
        starttime       = ""
        endtime         = ""
        recurrence      = "00 15 * * 1-5"
        suspend         = false
    }]


    api = {
      # use custom ALB to add custom header 
      # custom_load_balancer = true
      dev = {
        instance_type               = "t3.small,t2.small,t3a.small"
        associate_public_ip_address = true
        enable_spot_instances       = true
        autoscale_min               = 1
        autoscale_max               = 1
        environment_type            = "LoadBalanced"
      }
      stage = {
        instance_type               = "t3.small,t2.small,t3a.small"
        associate_public_ip_address = false
        enable_spot_instances       = false
        autoscale_min               = 1
        autoscale_max               = 1
        environment_type            = "LoadBalanced"
      }
      prod = {
        instance_type               = "t3.medium,t2.medium"
        associate_public_ip_address = false
        enable_spot_instances       = false
        autoscale_min               = 1
        autoscale_max               = 2
        environment_type            = "LoadBalanced"
      }
    }

    batch = {
      dev = {
        instance_type               = "t3.small,t2.small,t3a.small"
        associate_public_ip_address = true
        enable_spot_instances       = true
        autoscale_min               = 1
        autoscale_max               = 1
        environment_type            = "SingleInstance"
      }
      stage = {
        instance_type               = "t3.small,t2.small,t3a.small"
        associate_public_ip_address = false
        enable_spot_instances       = false
        autoscale_min               = 1
        autoscale_max               = 1
        environment_type            = "SingleInstance"
      }
      prod = {
        instance_type               = "t3.medium,t2.medium"
        associate_public_ip_address = false
        enable_spot_instances       = false
        autoscale_min               = 1
        autoscale_max               = 2
        environment_type            = "LoadBalanced"
      }
    }

    # logs_retention_in_days  = 60
    # loadbalancer_ssl_policy = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
    additional_settings = [
      {
        "name"      = "ConfigDocument"
        "namespace" = "aws:elasticbeanstalk:healthreporting:system"
        "value"     = "{\"Version\":1,\"CloudWatchMetrics\":{\"Instance\":{\"RootFilesystemUtil\":60,\"CPUUser\":60},\"Environment\":{\"ApplicationRequestsTotal\":60}},\"Rules\":{\"Environment\":{\"Application\":{\"ApplicationRequests4xx\":{\"Enabled\":true}}}}}"
      },
      {
        "name"      = "memory_limit"
        "namespace" = "aws:elasticbeanstalk:container:php:phpini"
        "value"     = "1024M"
      },
      {
        "name"      = "document_root"
        "namespace" = "aws:elasticbeanstalk:container:php:phpini"
        "value"     = "/public"
      }
    ]

  }


}