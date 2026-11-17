resource "aws_cloudfront_response_headers_policy" "custom_s3_buckets" {
  for_each = {
    for k, v in local.custom_s3_buckets : k => v if v["cloudfront_dedicated_distribution"] == true && length(coalesce(v["cloudfront_custom_response_headers"], [])) > 0
  }

  name    = "${local.resource_prefix}-${each.key}-custom-bucket"
  comment = "${local.resource_prefix} ${each.key} custom bucket"

  custom_headers_config {
    dynamic "items" {
      for_each = each.value["cloudfront_custom_response_headers"]

      content {
        header   = items.value["header"]
        value    = items.value["value"]
        override = items.value["override"]
      }
    }
  }
}
