include "root" {
  path = find_in_parent_folders()
}

include "modules" {
    path = "${dirname(find_in_parent_folders())}/modules/eb-env.hcl"
}

dependency "s3_ec2" {
  config_path = "${dirname(find_in_parent_folders())}/_env/s3/ec2"
  mock_outputs = {
    s3_bucket_arn = "arn:aws:s3:::*"
  }
}

inputs = {
  extended_ec2_policy_document = templatefile(
    "${dirname(find_in_parent_folders())}/templates/iam/s3-access.json.tpl",
    {
      "s3_resources" = try(dependency.s3_ec2.outputs.s3_bucket_arn, "arn:aws:s3:::*")
    }
  )
}