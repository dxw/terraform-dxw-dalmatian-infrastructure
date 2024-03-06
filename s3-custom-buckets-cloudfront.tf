resource "aws_cloudfront_distribution" "custom_s3_buckets" {
  for_each = {
    for k, v in local.custom_s3_buckets : k => v if v["cloudfront_dedicated_distribution"] == true
  }

  enabled         = true
  aliases         = ["${each.key}-bucket.${local.infrastructure_route53_domain}"]
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
    domain_name              = aws_s3_bucket.custom[each.key].bucket_regional_domain_name
    origin_id                = "${each.key}-custom-bucket"
    origin_access_control_id = aws_cloudfront_origin_access_control.custom_s3_buckets[each.key].id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = "${each.key}-custom-bucket"
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = aws_cloudfront_cache_policy.custom_s3_buckets[each.key].id

    dynamic "function_association" {
      for_each = each.value["cloudfront_s3_root"] != null ? [1] : []

      content {
        event_type   = "viewer-request"
        function_arn = aws_cloudfront_function.custom_s3_buckets_viewer_request[each.key].arn
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.infrastructure_logs[0].bucket_domain_name
    prefix          = "cloudfront/custom-s3-buckets/${each.key}"
  }

  tags = {
    Name = "${local.resource_prefix}-custom-s3-bucket-${each.key}"
  }

  depends_on = [
    aws_s3_bucket_acl.infrastructure_logs_log_delivery_write,
  ]
}
