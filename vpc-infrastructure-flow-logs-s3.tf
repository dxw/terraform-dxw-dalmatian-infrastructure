resource "aws_flow_log" "infrastructure_vpc_flow_logs_s3" {
  count = local.infrastructure_vpc_flow_logs_s3_with_athena ? 1 : 0

  log_destination_type = "s3"
  log_destination      = "${aws_s3_bucket.infrastructure_logs[0].arn}/${local.infrastructure_vpc_flow_logs_s3_key_prefix}"
  traffic_type         = local.infrastructure_vpc_flow_logs_traffic_type
  vpc_id               = aws_vpc.infrastructure[0].id

  destination_options {
    file_format        = "parquet"
    per_hour_partition = true
  }
}
