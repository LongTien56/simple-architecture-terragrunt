## DNS:
variable "public_hosts" {
  description = "The dns name value of the host"
  type        = list(string)
  default     = []
}

variable "domain_name" {
  description = "Public DNS domain name"
  type        = string
}

data "aws_route53_zone" "public" {
  name         = lower(var.domain_name)
  private_zone = false
}

resource "aws_route53_record" "public" {
  count   = length(var.public_hosts)
  zone_id = data.aws_route53_zone.public.*.id[0]
  name    = "${var.public_hosts[count.index]}.${lower(var.domain_name)}"
  type    = "A"

  alias {
    name                   = element(concat(aws_cloudfront_distribution.this.*.domain_name, [""]), 0)
    zone_id                = element(concat(aws_cloudfront_distribution.this.*.hosted_zone_id, [""]), 0)
    evaluate_target_health = false
  }
}