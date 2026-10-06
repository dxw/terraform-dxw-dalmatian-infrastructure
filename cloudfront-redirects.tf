data "aws_cloudfront_cache_policy" "cloudfront_redirects_caching_disabled" {
  count = length(local.cloudfront_redirects) > 0 ? 1 : 0

  name = "Managed-CachingDisabled"
}

resource "aws_cloudfront_function" "cloudfront_redirects" {
  for_each = local.cloudfront_redirects

  name    = "${local.resource_prefix_hash}-${each.key}-redirect"
  runtime = "cloudfront-js-2.0"
  comment = "${local.resource_prefix} ${each.key} redirect"
  publish = true
  code = templatefile("${path.root}/cloudfront-functions/redirect.js.tpl", {
    target             = jsonencode(each.value["target"])
    status_code        = each.value["status_code"]
    status_description = jsonencode(local.cloudfront_redirect_status_descriptions[tostring(each.value["status_code"])])
    preserve_path      = jsonencode(each.value["preserve_path"])
  })
}

resource "aws_acm_certificate" "cloudfront_redirects" {
  for_each = {
    for k, v in local.cloudfront_redirects : k => v if v["tls_certificate_arn"] == null
  }

  provider = aws.useast1

  domain_name               = each.value["aliases"][0]
  subject_alternative_names = slice(each.value["aliases"], 1, length(each.value["aliases"]))
  validation_method         = "DNS"

  tags = {
    Name = "${local.resource_prefix}-redirect-${each.key}"
  }

  lifecycle {
    create_before_destroy = true

    precondition {
      condition     = alltrue([for alias in each.value["aliases"] : local.cloudfront_redirect_alias_zones[alias] != null])
      error_message = "Redirect ${each.key}: with no tls_certificate_arn the certificate is validated in custom_route53_hosted_zones, but these aliases fall in no zone there: ${join(", ", [for alias in each.value["aliases"] : alias if local.cloudfront_redirect_alias_zones[alias] == null])}."
    }
  }
}

resource "aws_route53_record" "cloudfront_redirects_certificate_validation" {
  for_each = {
    for k, v in local.cloudfront_redirect_aliases : k => v
    if v["zone"] != null && local.cloudfront_redirects[v["redirect"]]["tls_certificate_arn"] == null
  }

  zone_id = aws_route53_zone.custom[each.value["zone"]].zone_id
  name    = one([for dvo in aws_acm_certificate.cloudfront_redirects[each.value["redirect"]].domain_validation_options : dvo.resource_record_name if dvo.domain_name == each.value["alias"]])
  type    = one([for dvo in aws_acm_certificate.cloudfront_redirects[each.value["redirect"]].domain_validation_options : dvo.resource_record_type if dvo.domain_name == each.value["alias"]])
  records = [one([for dvo in aws_acm_certificate.cloudfront_redirects[each.value["redirect"]].domain_validation_options : dvo.resource_record_value if dvo.domain_name == each.value["alias"]])]
  ttl     = 300

  # The same validation CNAME may already be declared in cname_records.
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "cloudfront_redirects" {
  for_each = aws_acm_certificate.cloudfront_redirects

  provider = aws.useast1

  certificate_arn = each.value.arn
  validation_record_fqdns = [
    for k, record in aws_route53_record.cloudfront_redirects_certificate_validation : record.fqdn
    if local.cloudfront_redirect_aliases[k]["redirect"] == each.key
  ]
}

resource "aws_cloudfront_distribution" "cloudfront_redirects" {
  for_each = local.cloudfront_redirects

  enabled         = true
  comment         = "${local.resource_prefix} ${each.key} redirect"
  aliases         = each.value["aliases"]
  is_ipv6_enabled = true
  http_version    = "http2and3"
  price_class     = "PriceClass_100"

  viewer_certificate {
    acm_certificate_arn      = each.value["tls_certificate_arn"] != null ? each.value["tls_certificate_arn"] : aws_acm_certificate_validation.cloudfront_redirects[each.key].certificate_arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }

  # Never contacted: the viewer-request function answers every request.
  origin {
    domain_name = regex("^https://([^/]+)", each.value["target"])[0]
    origin_id   = "${each.key}-redirect-target"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "${each.key}-redirect-target"
    viewer_protocol_policy = "allow-all"
    cache_policy_id        = data.aws_cloudfront_cache_policy.cloudfront_redirects_caching_disabled[0].id

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.cloudfront_redirects[each.key].arn
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  dynamic "logging_config" {
    for_each = each.value["access_logging_enabled"] ? [1] : []

    content {
      include_cookies = false
      bucket          = aws_s3_bucket.infrastructure_logs[0].bucket_domain_name
      prefix          = "cloudfront/redirects/${each.key}"
    }
  }

  tags = {
    Name = "${local.resource_prefix}-redirect-${each.key}"
  }

  lifecycle {
    precondition {
      condition     = length(flatten([for redirect in local.cloudfront_redirects : redirect["aliases"]])) == length(local.cloudfront_redirect_alias_zones)
      error_message = "cloudfront_redirects: an alias may appear in only one redirect, because CloudFront rejects an alias already attached to another distribution."
    }

    precondition {
      condition     = !each.value["create_route53_records"] || alltrue([for alias in each.value["aliases"] : local.cloudfront_redirect_alias_zones[alias] != null])
      error_message = "Redirect ${each.key}: create_route53_records writes into custom_route53_hosted_zones, but these aliases fall in no zone there: ${join(", ", [for alias in each.value["aliases"] : alias if local.cloudfront_redirect_alias_zones[alias] == null])}."
    }
  }

  depends_on = [
    aws_s3_bucket_acl.infrastructure_logs_log_delivery_write,
  ]
}

resource "aws_route53_record" "cloudfront_redirects_alias_a" {
  for_each = {
    for k, v in local.cloudfront_redirect_aliases : k => v
    if v["zone"] != null && local.cloudfront_redirects[v["redirect"]]["create_route53_records"]
  }

  zone_id = aws_route53_zone.custom[each.value["zone"]].zone_id
  name    = each.value["alias"]
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cloudfront_redirects[each.value["redirect"]].domain_name
    zone_id                = aws_cloudfront_distribution.cloudfront_redirects[each.value["redirect"]].hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "cloudfront_redirects_alias_aaaa" {
  for_each = {
    for k, v in local.cloudfront_redirect_aliases : k => v
    if v["zone"] != null && local.cloudfront_redirects[v["redirect"]]["create_route53_records"]
  }

  zone_id = aws_route53_zone.custom[each.value["zone"]].zone_id
  name    = each.value["alias"]
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.cloudfront_redirects[each.value["redirect"]].domain_name
    zone_id                = aws_cloudfront_distribution.cloudfront_redirects[each.value["redirect"]].hosted_zone_id
    evaluate_target_health = false
  }
}
