provider "aws" {
  region = local.aws_region

  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  region = "us-east-1"
  alias  = "useast1"

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

provider "datadog" {
  api_key  = local.infrastructure_datadog_api_key
  app_key  = local.infrastructure_datadog_app_key
  validate = local.infrastructure_datadog_api_key != "" && local.infrastructure_datadog_app_key != ""
  api_url  = local.infrastructure_datadog_api_url
}
