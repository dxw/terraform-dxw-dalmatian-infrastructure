resource "random_password" "infrastructure_ecs_cluster_service_cloudfront_bypass_protection_secret" {
  for_each = {
    for k, v in local.infrastructure_ecs_cluster_services : k => v if v["enable_cloudfront"] == true && v["cloudfront_bypass_protection_enabled"] == true
  }

  length           = 32
  special          = true
  override_special = "123456890"
}

resource "aws_cloudfront_distribution" "infrastructure_ecs_cluster_service_cloudfront" {
  for_each = {
    for k, v in local.infrastructure_ecs_cluster_services : k => v if v["enable_cloudfront"] == true
  }

  enabled         = true
  aliases         = ["${each.key}.${local.infrastructure_route53_domain}"]
  is_ipv6_enabled = true
  http_version    = "http2and3"
  price_class     = "PriceClass_100"

  viewer_certificate {
    acm_certificate_arn            = local.enable_infrastructure_wildcard_certificate ? aws_acm_certificate_validation.infrastructure_wildcard_us_east_1[0].certificate_arn : null
    cloudfront_default_certificate = local.enable_infrastructure_wildcard_certificate ? null : true
    minimum_protocol_version       = local.enable_infrastructure_wildcard_certificate ? "TLSv1.2_2021" : null
    ssl_support_method             = "sni-only"
  }

  origin {
    domain_name = local.enable_infrastructure_route53_hosted_zone ? aws_route53_record.service_loadbalancer_record_alb[0].name : aws_alb.infrastructure_ecs_cluster_service[0].dns_name
    origin_id   = "${each.key}-default"

    connection_attempts = 3
    connection_timeout  = 10

    dynamic "origin_shield" {
      for_each = each.value["cloudfront_origin_shield_enabled"] == true ? [1] : []

      content {
        enabled              = true
        origin_shield_region = local.aws_region
      }
    }

    dynamic "custom_header" {
      for_each = each.value["cloudfront_bypass_protection_enabled"] == true ? [1] : []

      content {
        name  = "X-CloudFront-Secret"
        value = random_password.infrastructure_ecs_cluster_service_cloudfront_bypass_protection_secret[each.key].result
      }
    }

    custom_origin_config {
      origin_protocol_policy   = local.enable_infrastructure_wildcard_certificate ? "https-only" : "http-only"
      http_port                = "80"
      https_port               = "443"
      origin_ssl_protocols     = ["TLSv1.2"]
      origin_keepalive_timeout = 5
      origin_read_timeout      = 30
    }
  }

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "${each.key}-default"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    cache_policy_id            = each.value["cloudfront_managed_cache_policy"] != null ? data.aws_cloudfront_cache_policy.managed_policy[each.value["cloudfront_managed_cache_policy"]].id : null
    origin_request_policy_id   = each.value["cloudfront_managed_origin_request_policy"] != null ? data.aws_cloudfront_origin_request_policy.managed_policy[each.value["cloudfront_managed_origin_request_policy"]].id : null
    response_headers_policy_id = each.value["cloudfront_managed_response_headers_policy"] != null ? data.aws_cloudfront_response_headers_policy.managed_policy[each.value["cloudfront_managed_response_headers_policy"]].id : null

    dynamic "forwarded_values" {
      for_each = each.value["cloudfront_managed_cache_policy"] == null ? [1] : []

      content {
        query_string = true

        headers = [
          "Accept",
          "Accept-Charset",
          "Accept-Datetime",
          "Accept-Encoding",
          "Accept-Language",
          "Authorization",
          "CloudFront-Forwarded-Proto",
          "Host",
          "Referer",
        ]

        cookies {
          forward = "all"
        }
      }
    }

  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  dynamic "logging_config" {
    for_each = each.value["cloudfront_access_logging_enabled"] == true ? [1] : []

    content {
      include_cookies = false
      bucket          = aws_s3_bucket.infrastructure_logs[0].bucket_domain_name
      prefix          = "cloudfront/infrasructure-ecs-cluster-service/${each.key}"
    }
  }

  tags = {
    Name = "${local.resource_prefix}-infrastructure-ecs-cluster-service-${each.key}"
  }

  depends_on = [
    aws_s3_bucket_acl.infrastructure_logs_log_delivery_write,
  ]
}
