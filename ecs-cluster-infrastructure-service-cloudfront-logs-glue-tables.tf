resource "aws_glue_catalog_database" "infrastructure_ecs_cluster_service_cloudfront_logs" {
  for_each = {
    for k, v in local.infrastructure_ecs_cluster_services : k => v if v["enable_cloudfront"] == true && v["cloudfront_access_logging_enabled"] == true
  }

  name        = "${replace(local.resource_prefix, "-", "_")}_infrastructure_ecs_cluster_service_${replace(each.key, "-", "_")}_logs"
  description = "Database for ${local.resource_prefix} ECS cluster service ${each.key} CloudFront log tables to be queried with Athena"
}

resource "aws_glue_catalog_table" "infrastructure_ecs_cluster_service_cloudfront_logs" {
  for_each = {
    for k, v in local.infrastructure_ecs_cluster_services : k => v if v["enable_cloudfront"] == true && v["cloudfront_access_logging_enabled"] == true
  }

  name          = "${replace(local.resource_prefix, "-", "_")}_infrastructure_ecs_cluster_service_${replace(each.key, "-", "_")}_logs"
  database_name = aws_glue_catalog_database.infrastructure_ecs_cluster_service_cloudfront_logs[each.key].name

  parameters = {
    comment                  = "CloudFront logs table for ${local.resource_prefix} ECS cluster service ${each.key}"
    EXTERNAL                 = "TRUE"
    "skip.header.line.count" = "2"
  }

  storage_descriptor {
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"
    location      = "s3://${aws_s3_bucket.infrastructure_logs[0].id}/cloudfront/infrasructure-ecs-cluster-service/${each.key}/"

    ser_de_info {
      name                  = "serde"
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"

      parameters = {
        "field.delim" : "\t"
        "serialization.format" : "\t"
      }
    }

    dynamic "columns" {
      for_each = local.infrastructure_ecs_cluster_service_cloudfront_logs_glue_table_columns
      content {
        name = columns.value["name"]
        type = columns.value["type"]
      }
    }
  }
}
