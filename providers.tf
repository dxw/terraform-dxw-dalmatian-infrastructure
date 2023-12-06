provider "aws" {
  region = local.aws_region

  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  region  = local.aws_region
  alias   = "awsroute53root"
  profile = local.aws_profile_name_route53_root != "" ? local.aws_profile_name_route53_root : null

  default_tags {
    tags = local.default_tags
  }
}
