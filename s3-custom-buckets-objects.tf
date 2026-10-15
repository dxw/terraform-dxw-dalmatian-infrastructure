locals {
  custom_s3_bucket_object_content_types = {
    css  = "text/css; charset=utf-8"
    html = "text/html; charset=utf-8"
    ico  = "image/x-icon"
    jpg  = "image/jpeg"
    js   = "text/javascript; charset=utf-8"
    json = "application/json"
    png  = "image/png"
    svg  = "image/svg+xml"
    txt  = "text/plain; charset=utf-8"
    webp = "image/webp"
  }
  # Keyed "<bucket>/<key>": a bucket name cannot contain a slash, so the split is unambiguous.
  custom_s3_bucket_objects = merge([
    for bucket, v in local.custom_s3_buckets : {
      for key, object in v["objects"] != null ? v["objects"] : {} :
      "${bucket}/${key}" => merge(object, { bucket = bucket, key = key })
    }
  ]...)
}

resource "aws_s3_object" "custom_s3_buckets" {
  for_each = local.custom_s3_bucket_objects

  bucket        = aws_s3_bucket.custom[each.value["bucket"]].id
  key           = each.value["key"]
  content       = each.value["content"]
  etag          = md5(each.value["content"])
  content_type  = each.value["content_type"] != null ? each.value["content_type"] : lookup(local.custom_s3_bucket_object_content_types, lower(element(split(".", each.value["key"]), length(split(".", each.value["key"])) - 1)), "application/octet-stream")
  cache_control = each.value["cache_control"]
  kms_key_id    = (local.infrastructure_kms_encryption || local.custom_s3_buckets[each.value["bucket"]]["create_dedicated_kms_key"] == true) && local.custom_s3_buckets[each.value["bucket"]]["use_aes256_encryption"] != true ? (local.custom_s3_buckets[each.value["bucket"]]["create_dedicated_kms_key"] == true ? aws_kms_key.custom_s3_buckets[each.value["bucket"]].arn : aws_kms_key.infrastructure[0].arn) : null

  depends_on = [aws_s3_bucket_server_side_encryption_configuration.custom]
}
