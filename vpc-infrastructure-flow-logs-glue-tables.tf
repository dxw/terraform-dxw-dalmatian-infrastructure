resource "aws_glue_catalog_database" "infrastructure_vpc_flow_logs" {
  count = local.infrastructure_vpc_flow_logs_s3_with_athena ? 1 : 0

  name        = "${replace(local.resource_prefix, "-", "_")}_infrastructure_vpc_logs"
  description = "Database for ${local.resource_prefix} VPC flow log tables to be queried with Athena"
}

resource "aws_glue_catalog_table" "infrastructure_vpc_flow_logs" {
  count = local.infrastructure_vpc_flow_logs_s3_with_athena ? 1 : 0

  name          = "${replace(local.resource_prefix, "-", "_")}_infrastructure_vpc_logs"
  database_name = aws_glue_catalog_database.infrastructure_vpc_flow_logs[0].name

  dynamic "partition_keys" {
    for_each = local.infrastructure_vpc_flow_logs_glue_table_partition_keys
    content {
      name = partition_keys.value["name"]
      type = partition_keys.value["type"]
    }
  }

  parameters = {
    comment                     = "VPC Flow logs table for ${local.resource_prefix} infrastructure VPC"
    EXTERNAL                    = "TRUE"
    "skip.header.line.count"    = "1"
    "projection.enabled"        = "true"
    "projection.year.type"      = "integer"
    "projection.year.digits"    = "4"
    "projection.year.range"     = "2014,2050"
    "projection.month.type"     = "integer"
    "projection.month.range"    = "00,12"
    "projection.month.digits"   = "2"
    "projection.day.type"       = "integer"
    "projection.day.range"      = "00,31"
    "projection.day.digits"     = "2"
    "projection.hour.type"      = "integer"
    "projection.hour.range"     = "00,23"
    "projection.hour.digits"    = "2"
    "storage.location.template" = "s3://${aws_s3_bucket.infrastructure_logs[0].id}/${local.infrastructure_vpc_flow_logs_s3_key_prefix}/AWSLogs/${local.aws_account_id}/vpcflowlogs/${local.aws_region}/$${year}/$${month}/$${day}/$${hour}"
  }

  storage_descriptor {
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"
    location      = "s3://${aws_s3_bucket.infrastructure_logs[0].id}/${local.infrastructure_vpc_flow_logs_s3_key_prefix}/AWSLogs/${local.aws_account_id}/vpcflowlogs"

    ser_de_info {
      parameters = {
        "serialization.format" = "1"
      }
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
    }

    dynamic "columns" {
      for_each = local.infrastructure_vpc_flow_logs_glue_table_columns
      content {
        name = columns.value["name"]
        type = columns.value["type"]
      }
    }
  }
}
