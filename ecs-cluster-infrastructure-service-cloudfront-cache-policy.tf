resource "aws_cloudfront_cache_policy" "infrastructure_ecs_cluster_service" {
  for_each = local.infrastructure_ecs_cluster_service_cloudfront_cache_policies

  name        = "${local.resource_prefix}-${each.value["service"]}-${each.value["key"]}"
  comment     = "${local.resource_prefix} ${each.value["service"]} service ${each.value["key"]}"
  min_ttl     = each.value["min_ttl"]
  default_ttl = each.value["default_ttl"]
  max_ttl     = each.value["max_ttl"]

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true

    cookies_config {
      cookie_behavior = each.value["cookies_in_cache_key"]
    }

    # Host is always forwarded: the service ALB routes on it and answers 421
    # without it, and a cache policy only forwards headers it keys on unless
    # an origin request policy adds them.
    headers_config {
      header_behavior = "whitelist"

      headers {
        items = distinct(concat(["Host"], each.value["headers_in_cache_key"]))
      }
    }

    query_strings_config {
      query_string_behavior = each.value["query_strings_in_cache_key"]
    }
  }

  lifecycle {
    # The "<service>-<policy>" key and the AWS name are both ambiguous when a
    # service name and a policy key share a hyphen boundary (service "a-b"
    # with policy "c" against service "a" with policy "b-c"). A dropped key
    # shows as a count mismatch; a name clash would fail at the AWS API.
    precondition {
      condition     = length(local.infrastructure_ecs_cluster_service_cloudfront_cache_policies) == local.infrastructure_ecs_cluster_service_cloudfront_cache_policies_declared
      error_message = "Two cloudfront_cache_policies resolve to the same <service>-<policy> name; rename one so every service and policy pair is distinct."
    }
    precondition {
      condition     = contains(["none", "all"], each.value["cookies_in_cache_key"]) && contains(["none", "all"], each.value["query_strings_in_cache_key"])
      error_message = "Cache policy ${each.value["key"]} on service ${each.value["service"]}: cookies_in_cache_key and query_strings_in_cache_key must be none or all."
    }
  }
}
