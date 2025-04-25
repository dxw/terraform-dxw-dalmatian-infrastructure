resource "aws_cloudfront_function" "custom_s3_buckets_viewer_request" {
  for_each = {
    for k, v in local.custom_s3_buckets : k => v if v["cloudfront_infrastructure_ecs_cluster_service_path"] != null || v["cloudfront_s3_root"] != null
  }

  name    = "${local.resource_prefix_hash}-${each.key}-bucket-viewer-request"
  runtime = "cloudfront-js-2.0"
  comment = "${local.resource_prefix} ${each.key} bucket viewer request"
  publish = true
  code = templatefile("${path.root}/cloudfront-functions/viewer-request.js.tpl", {
    new_root              = each.value["cloudfront_s3_root"] != null ? each.value["cloudfront_s3_root"] : "/"
    trim_request_dirs_num = each.value["cloudfront_infrastructure_ecs_cluster_service_path"] != null ? length(split("/", each.value["cloudfront_infrastructure_ecs_cluster_service_path"])) - 2 : 0
    basic_auth_user_list  = each.value["cloudfront_basic_auth_user_list"] != null ? jsonencode(each.value["cloudfront_basic_auth_user_list"]) : "{}"
  })
}
