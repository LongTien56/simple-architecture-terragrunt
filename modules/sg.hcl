terraform {
    source = "${dirname(find_in_parent_folders())}/local-modules/sg"
}
dependency "vpc" {
    config_path = "${dirname(find_in_parent_folders())}/demo/ap-southeast-1/vpc"
    mock_outputs = {
        vpc_id = "vpc-1234"
    }
}




inputs = {
    vpc_id = dependency.vpc.outputs.vpc_id
}


