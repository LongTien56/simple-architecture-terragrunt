## Bucket policy:
variable "origin_bucket" {
  type        = string
  description = "The origin bucket id"
}

data "aws_iam_policy_document" "s3_origin" {
  statement {
    sid = "S3GetObjectForCloudFront"

    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${var.origin_bucket}/*"]

    principals {
      type        = "AWS"
      identifiers = [values(aws_cloudfront_origin_access_identity.this)[0].iam_arn]
    }
  }

  statement {
    sid = "S3ListBucketForCloudFront"

    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.origin_bucket}"]

    principals {
      type        = "AWS"
      identifiers = [values(aws_cloudfront_origin_access_identity.this)[0].iam_arn]
    }
  }

  statement {
    sid     = "ForceSSLOnlyAccess"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      "arn:aws:s3:::${var.origin_bucket}",
      "arn:aws:s3:::${var.origin_bucket}/*"
    ]

    principals {
      identifiers = ["*"]
      type        = "*"
    }

    condition {
      test     = "Bool"
      values   = ["false"]
      variable = "aws:SecureTransport"
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = var.origin_bucket
  policy = join("", data.aws_iam_policy_document.s3_origin.*.json)
}
