resource "aws_cloudfront_cache_policy" "custom_s3_buckets" {
  for_each = {
    for k, v in local.custom_s3_buckets : k => v if v["cloudfront_dedicated_distribution"] == true || v["cloudfront_infrastructure_ecs_cluster_service"] != null
  }

  name        = "${local.resource_prefix}-${each.key}-custom-bucket"
  comment     = "${local.resource_prefix} ${each.key} custom bucket"
  default_ttl = 86400
  max_ttl     = 31536000
  min_ttl     = 1

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
  }
}
