resource "aws_cloudformation_stack" "custom" {
  for_each = local.custom_cloudformation_stacks

  name              = "${local.resource_prefix_hash}-${each.key}"
  parameters        = each.value["parameters"]
  template_body     = each.value["template_body"]
  template_url      = local.enable_cloudformatian_s3_template_store && each.value["s3_template_store_key"] != null ? sensitive(data.external.s3_presigned_url["${aws_s3_bucket.cloudformation_custom_stack_template_store[0].id}/${each.value["s3_template_store_key"]}"].result.url) : null
  on_failure        = each.value["on_failure"] != null ? each.value["on_failure"] : "DO_NOTHING"
  notification_arns = []
  capabilities      = each.value["capabilities"] != null ? each.value["capabilities"] : []
}
