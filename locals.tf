locals {
  project_name         = var.project_name
  infrastructure_name  = var.infrastructure_name
  environment          = var.environment
  aws_region           = var.aws_region
  aws_account_id       = data.aws_caller_identity.current.account_id
  resource_prefix      = "${var.project_name}-${var.infrastructure_name}-${var.environment}"
  resource_prefix_hash = format("%.8s", sha512(local.resource_prefix))

  infrastructure_kms_encryption = var.infrastructure_kms_encryption

  infrastructure_logging_bucket_retention = var.infrastructure_logging_bucket_retention

  enable_infrastructure_logs_bucket = (
    local.infrastructure_vpc_flow_logs_s3_with_athena
  )
  logs_bucket_source_arns = concat(
    local.infrastructure_vpc_flow_logs_s3_with_athena ? ["arn:aws:logs:${local.aws_region}:${local.aws_account_id}:*"] : [],
  )

  infrastructure_vpc                                      = var.infrastructure_vpc
  infrastructure_vpc_cidr_block                           = var.infrastructure_vpc_cidr_block
  infrastructure_vpc_enable_dns_support                   = var.infrastructure_vpc_enable_dns_support
  infrastructure_vpc_enable_dns_hostnames                 = var.infrastructure_vpc_enable_dns_hostnames
  infrastructure_vpc_instance_tenancy                     = var.infrastructure_vpc_instance_tenancy
  infrastructure_vpc_enable_network_address_usage_metrics = var.infrastructure_vpc_enable_network_address_usage_metrics
  infrastructure_vpc_assign_generated_ipv6_cidr_block     = var.infrastructure_vpc_assign_generated_ipv6_cidr_block
  infrastructure_vpc_flow_logs_cloudwatch_logs            = var.infrastructure_vpc_flow_logs_cloudwatch_logs && local.infrastructure_vpc
  infrastructure_vpc_flow_logs_s3_with_athena             = var.infrastructure_vpc_flow_logs_s3_with_athena && local.infrastructure_vpc
  infrastructure_vpc_flow_logs_s3_key_prefix              = trim(var.infrastructure_vpc_flow_logs_s3_key_prefix, "/")
  infrastructure_vpc_flow_logs_retention                  = var.infrastructure_vpc_flow_logs_retention
  infrastructure_vpc_flow_logs_traffic_type               = var.infrastructure_vpc_flow_logs_traffic_type
  infrastructure_vpc_flow_logs_glue_table_columns = {
    version             = "int",
    account_id          = "string",
    interface_id        = "string",
    srcaddr             = "string",
    dstaddr             = "string",
    srcport             = "int",
    dstport             = "int",
    protocol            = "bigint",
    packets             = "bigint",
    bytes               = "bigint",
    start               = "bigint",
    "`end`"             = "bigint",
    action              = "string",
    log_status          = "string",
    vpc_id              = "string",
    subnet_id           = "string",
    instance_id         = "string",
    tcp_flags           = "int",
    type                = "string",
    pkt_srcaddr         = "string",
    pkt_dstaddr         = "string",
    az_id               = "string",
    sublocation_type    = "string",
    sublocation_id      = "string",
    pkt_src_aws_service = "string",
    pkt_dst_aws_service = "string",
    flow_direction      = "string",
    traffic_path        = "int",
  }
  infrastructure_vpc_flow_logs_glue_table_partition_keys = {
    region = "string",
    date   = "string",
    hour   = "string"
  }

  default_tags = {
    Project        = local.project_name,
    Infrastructure = local.infrastructure_name,
    Environment    = local.environment,
    Prefix         = local.resource_prefix,
  }
}
