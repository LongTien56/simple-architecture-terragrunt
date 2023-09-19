locals {
    project_name = "dev_tienll"

    vpc_settings = {
        azs             = ["ap-southeast-1a", "ap-southeast-1b"]
        private_subnets = ["10.0.0.0/19", "10.0.32.0/19"]
        public_subnets  = ["10.0.64.0/19", "10.0.96.0/19"]
        dev = {


            enable_nat_gateway = false
            single_nat_gateway = false
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
            target_group_index = 0
            }
        ]
   
    }


    rds_settings = {
        engine = "aurora-mysql"
        engine_version = "8.0.mysql_aurora.3.04.0"

        dev = {
            instance_class = "db.t3.medium"
            instances = {
                one = {}
                two = {}
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
                two = {}
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

}