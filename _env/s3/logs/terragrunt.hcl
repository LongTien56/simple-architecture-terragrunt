include "root" {
  path = find_in_parent_folders()
}
include "modules" {
    path = "${dirname(find_in_parent_folders())}/modules/s3.hcl"
}

inputs = {
  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  attach_elb_log_delivery_policy = true  # Required for ALB logs
  attach_lb_log_delivery_policy  = true  # Required for ALB/NLB logs

  lifecycle_rule = [
    {
      id      = "save"
      enabled = true
      prefix  = ""

      transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
          }, {
          days          = 180
          storage_class = "GLACIER"
        }
      ]

      abort_incomplete_multipart_upload_days = 7
    }
  ]
}