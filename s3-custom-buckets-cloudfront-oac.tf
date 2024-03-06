resource "aws_cloudfront_origin_access_control" "custom_s3_buckets" {
  for_each = {
    for k, v in local.custom_s3_buckets : k => v if v["cloudfront_dedicated_distribution"] == true || v["cloudfront_infrastructure_ecs_cluster_service"] != null
  }

  name                              = "${local.resource_prefix_hash}-${substr(sha512(each.key), 0, 6)}-custom-bucket"
  description                       = "${local.resource_prefix} ${each.key} custom bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}
