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

  infrastructure_slack_sns_topic_name    = "${local.project_name}-cloudwatch-slack-alerts"
  infrastructure_opsgenie_sns_topic_name = "${local.project_name}-cloudwatch-opsgenie-alerts"
  infrastructure_slack_sns_topic_in_use = (
    local.infrastructure_ecs_cluster_asg_cpu_alert_slack ||
    local.infrastructure_ecs_cluster_pending_task_alert_slack ||
    local.infrastructure_ecs_cluster_ecs_asg_diff_alert_slack
  )
  infrastructure_opsgenie_sns_topic_in_use = (
    local.infrastructure_ecs_cluster_asg_cpu_alert_opsgenie ||
    local.infrastructure_ecs_cluster_pending_task_alert_opsgenie ||
    local.infrastructure_ecs_cluster_ecs_asg_diff_alert_opsgenie
  )

  enable_infrastructure_logs_bucket = (
    local.infrastructure_vpc_flow_logs_s3_with_athena ||
    length(local.infrastructure_ecs_cluster_services) != 0 ||
    length(local.custom_s3_buckets) != 0 ||
    local.enable_cloudformatian_s3_template_store ||
    local.enable_infrastructure_vpc_transfer_s3_bucket ||
    local.infrastructure_ecs_cluster_enable_execute_command_logging ||
    local.enable_infrastructure_rds_backup_to_s3
  )
  logs_bucket_s3_source_arns = concat(
    length(local.infrastructure_ecs_cluster_services) != 0 ? [aws_s3_bucket.infrastructure_ecs_cluster_service_build_pipeline_artifact_store[0].arn] : [],
    local.enable_infrastructure_vpc_transfer_s3_bucket ? [aws_s3_bucket.infrastructure_vpc_transfer[0].arn] : [],
    [for k, v in local.custom_s3_buckets : aws_s3_bucket.custom[k].arn],
    local.enable_infrastructure_rds_backup_to_s3 ? [aws_s3_bucket.infrastructure_rds_s3_backups[0].arn] : [],
  )
  logs_bucket_logs_source_arns = concat(
    local.infrastructure_vpc_flow_logs_s3_with_athena ? ["arn:aws:logs:${local.aws_region}:${local.aws_account_id}:*"] : []
  )

  route53_root_hosted_zone_domain_name      = var.route53_root_hosted_zone_domain_name
  aws_profile_name_route53_root             = var.aws_profile_name_route53_root
  enable_infrastructure_route53_hosted_zone = var.enable_infrastructure_route53_hosted_zone
  create_infrastructure_route53_delegations = local.route53_root_hosted_zone_domain_name != "" && local.aws_profile_name_route53_root != "" && local.enable_infrastructure_route53_hosted_zone
  infrastructure_route53_domain             = "${local.environment}.${var.infrastructure_name}.${local.route53_root_hosted_zone_domain_name}"

  enable_infrastructure_wildcard_certificate = local.enable_infrastructure_route53_hosted_zone && length(local.infrastructure_ecs_cluster_services) > 0

  infrastructure_vpc                                          = var.infrastructure_vpc
  infrastructure_vpc_cidr_block                               = var.infrastructure_vpc_cidr_block
  infrastructure_vpc_enable_dns_support                       = var.infrastructure_vpc_enable_dns_support
  infrastructure_vpc_enable_dns_hostnames                     = var.infrastructure_vpc_enable_dns_hostnames
  infrastructure_vpc_instance_tenancy                         = var.infrastructure_vpc_instance_tenancy
  infrastructure_vpc_enable_network_address_usage_metrics     = var.infrastructure_vpc_enable_network_address_usage_metrics
  infrastructure_vpc_assign_generated_ipv6_cidr_block         = var.infrastructure_vpc_assign_generated_ipv6_cidr_block
  infrastructure_vpc_network_enable_public                    = local.infrastructure_vpc && var.infrastructure_vpc_network_enable_public
  infrastructure_vpc_network_enable_private                   = local.infrastructure_vpc && var.infrastructure_vpc_network_enable_private
  infrastructure_vpc_network_availability_zones               = toset(sort(var.infrastructure_vpc_network_availability_zones))
  infrastructure_vpc_network_public_cidr                      = cidrsubnet(local.infrastructure_vpc_cidr_block, 1, 0)
  infrastructure_vpc_network_public_cidr_prefix               = basename(local.infrastructure_vpc_network_public_cidr)
  infrastructure_vpc_network_public_cidr_newbits              = 24 - local.infrastructure_vpc_network_public_cidr_prefix
  infrastructure_vpc_network_private_cidr                     = cidrsubnet(local.infrastructure_vpc_cidr_block, 1, 1)
  infrastructure_vpc_network_private_cidr_prefix              = basename(local.infrastructure_vpc_network_private_cidr)
  infrastructure_vpc_network_private_cidr_newbits             = 24 - local.infrastructure_vpc_network_private_cidr_prefix
  infrastructure_vpc_network_acl_egress_lockdown_private      = var.infrastructure_vpc_network_acl_egress_lockdown_private
  infrastructure_vpc_network_acl_egress_custom_rules_private  = var.infrastructure_vpc_network_acl_egress_custom_rules_private
  infrastructure_vpc_network_acl_ingress_lockdown_private     = var.infrastructure_vpc_network_acl_ingress_lockdown_private
  infrastructure_vpc_network_acl_ingress_custom_rules_private = var.infrastructure_vpc_network_acl_ingress_custom_rules_private
  infrastructure_vpc_network_acl_egress_lockdown_public       = var.infrastructure_vpc_network_acl_egress_lockdown_public
  infrastructure_vpc_network_acl_egress_custom_rules_public   = var.infrastructure_vpc_network_acl_egress_custom_rules_public
  infrastructure_vpc_network_acl_ingress_lockdown_public      = var.infrastructure_vpc_network_acl_ingress_lockdown_public
  infrastructure_vpc_network_acl_ingress_custom_rules_public  = var.infrastructure_vpc_network_acl_ingress_custom_rules_public
  infrastructure_vpc_flow_logs_cloudwatch_logs                = var.infrastructure_vpc_flow_logs_cloudwatch_logs && local.infrastructure_vpc
  infrastructure_vpc_flow_logs_s3_with_athena                 = var.infrastructure_vpc_flow_logs_s3_with_athena && local.infrastructure_vpc
  infrastructure_vpc_flow_logs_s3_key_prefix                  = trim(var.infrastructure_vpc_flow_logs_s3_key_prefix, "/")
  infrastructure_vpc_flow_logs_retention                      = var.infrastructure_vpc_flow_logs_retention
  infrastructure_vpc_flow_logs_traffic_type                   = var.infrastructure_vpc_flow_logs_traffic_type
  infrastructure_vpc_flow_logs_glue_table_columns = [
    { name = "version", type = "int" },
    { name = "account_id", type = "string" },
    { name = "interface_id", type = "string" },
    { name = "srcaddr", type = "string" },
    { name = "dstaddr", type = "string" },
    { name = "srcport", type = "int" },
    { name = "dstport", type = "int" },
    { name = "protocol", type = "bigint" },
    { name = "packets", type = "bigint" },
    { name = "bytes", type = "bigint" },
    { name = "start", type = "bigint" },
    { name = "`end`", type = "bigint" },
    { name = "action", type = "string" },
    { name = "log_status", type = "string" },
    { name = "vpc_id", type = "string" },
    { name = "subnet_id", type = "string" },
    { name = "instance_id", type = "string" },
    { name = "tcp_flags", type = "int" },
    { name = "type", type = "string" },
    { name = "pkt_srcaddr", type = "string" },
    { name = "pkt_dstaddr", type = "string" },
    { name = "az_id", type = "string" },
    { name = "sublocation_type", type = "string" },
    { name = "sublocation_id", type = "string" },
    { name = "pkt_src_aws_service", type = "string" },
    { name = "pkt_dst_aws_service", type = "string" },
    { name = "flow_direction", type = "string" },
    { name = "traffic_path", type = "int" },
  ]
  infrastructure_vpc_flow_logs_glue_table_partition_keys = [
    { name = "year", type = "int" },
    { name = "month", type = "int" },
    { name = "day", type = "int" },
    { name = "hour", type = "int" },
  ]
  enable_infrastructure_vpc_transfer_s3_bucket = var.enable_infrastructure_vpc_transfer_s3_bucket
  infrastructure_vpc_transfer_s3_bucket_access_vpc_ids = concat(
    local.infrastructure_vpc ? [aws_vpc.infrastructure[0].id] : [],
    var.infrastructure_vpc_transfer_s3_bucket_access_vpc_ids
  )
  infrastructure_vpc_transfer_ssm_download_command = "aws s3 cp {{ Source }} {{ HostTarget }} {{ Recursive  }}; if [ -n \\\"{{ TargetUID }}\\\" ] && [ -n \\\"{{ TargetGID }}\\\" ]; then chown {{ TargetUID }}:{{ TargetGID }} -R {{ HostTarget }}; fi"
  infrastructure_vpc_transfer_ssm_upload_command   = "aws s3 cp {{ Source }} {{ S3Target }} {{ Recursive }}"

  infrastructure_dockerhub_email    = var.infrastructure_dockerhub_email
  infrastructure_dockerhub_username = var.infrastructure_dockerhub_username
  infrastructure_dockerhub_token    = var.infrastructure_dockerhub_token

  enable_infrastructure_ecs_cluster                                = var.enable_infrastructure_ecs_cluster && local.infrastructure_vpc
  infrastructure_ecs_cluster_name                                  = "${local.resource_prefix}-infrastructure"
  infrastructure_ecs_cluster_ami_version                           = var.infrastructure_ecs_cluster_ami_version
  infrastructure_ecs_cluster_ebs_docker_storage_volume_device_name = "/dev/xvdcz"
  infrastructure_ecs_cluster_ebs_docker_storage_volume_size        = var.infrastructure_ecs_cluster_ebs_docker_storage_volume_size
  infrastructure_ecs_cluster_ebs_docker_storage_volume_type        = var.infrastructure_ecs_cluster_ebs_docker_storage_volume_type
  infrastructure_ecs_cluster_publicly_avaialble                    = var.infrastructure_ecs_cluster_publicly_avaialble && local.infrastructure_vpc_network_enable_public
  infrastructure_ecs_cluster_custom_security_group_rules           = var.infrastructure_ecs_cluster_custom_security_group_rules
  infrastructure_ecs_cluster_instance_type                         = var.infrastructure_ecs_cluster_instance_type
  infrastructure_ecs_cluster_termination_timeout                   = var.infrastructure_ecs_cluster_termination_timeout
  infrastructure_ecs_cluster_draining_lambda_enabled               = var.infrastructure_ecs_cluster_draining_lambda_enabled && local.enable_infrastructure_ecs_cluster
  infrastructure_ecs_cluster_draining_lambda_log_retention         = var.infrastructure_ecs_cluster_draining_lambda_log_retention
  infrastructure_ecs_cluster_termination_sns_topic_name            = "${local.resource_prefix}-infrastructure-ecs-cluster-termination"
  infrastructure_ecs_cluster_min_size                              = var.infrastructure_ecs_cluster_min_size
  infrastructure_ecs_cluster_max_size                              = var.infrastructure_ecs_cluster_max_size
  infrastructure_ecs_cluster_allow_kms_encryption = local.infrastructure_kms_encryption && anytrue([
    local.enable_infrastructure_vpc_transfer_s3_bucket,
  ])
  infrastructure_ecs_cluster_max_instance_lifetime      = var.infrastructure_ecs_cluster_max_instance_lifetime
  infrastructure_ecs_cluster_autoscaling_time_based_max = toset(var.infrastructure_ecs_cluster_autoscaling_time_based_max)
  infrastructure_ecs_cluster_autoscaling_time_based_min = toset(var.infrastructure_ecs_cluster_autoscaling_time_based_min)
  infrastructure_ecs_cluster_autoscaling_time_based_custom = {
    for custom in toset(var.infrastructure_ecs_cluster_autoscaling_time_based_custom) : "${custom["min"]}-${custom["max"]} ${custom["cron"]}" => custom
  }
  enable_infrastructure_ecs_cluster_asg_cpu_alert                     = var.enable_infrastructure_ecs_cluster_asg_cpu_alert && local.enable_infrastructure_ecs_cluster
  infrastructure_ecs_cluster_asg_cpu_alert_evaluation_periods         = var.infrastructure_ecs_cluster_asg_cpu_alert_evaluation_periods
  infrastructure_ecs_cluster_asg_cpu_alert_period                     = var.infrastructure_ecs_cluster_asg_cpu_alert_period
  infrastructure_ecs_cluster_asg_cpu_alert_threshold                  = var.infrastructure_ecs_cluster_asg_cpu_alert_threshold
  infrastructure_ecs_cluster_asg_cpu_alert_slack                      = var.infrastructure_ecs_cluster_asg_cpu_alert_slack && local.enable_infrastructure_ecs_cluster_asg_cpu_alert
  infrastructure_ecs_cluster_asg_cpu_alert_opsgenie                   = var.infrastructure_ecs_cluster_asg_cpu_alert_opsgenie && local.enable_infrastructure_ecs_cluster_asg_cpu_alert
  enable_infrastructure_ecs_cluster_pending_task_alert                = var.enable_infrastructure_ecs_cluster_pending_task_alert && local.enable_infrastructure_ecs_cluster
  infrastructure_ecs_cluster_pending_task_metric_lambda_log_retention = var.infrastructure_ecs_cluster_pending_task_metric_lambda_log_retention
  infrastructure_ecs_cluster_pending_task_alert_evaluation_periods    = var.infrastructure_ecs_cluster_pending_task_alert_evaluation_periods
  infrastructure_ecs_cluster_pending_task_alert_period                = var.infrastructure_ecs_cluster_pending_task_alert_period
  infrastructure_ecs_cluster_pending_task_alert_threshold             = var.infrastructure_ecs_cluster_pending_task_alert_threshold
  infrastructure_ecs_cluster_pending_task_alert_slack                 = var.infrastructure_ecs_cluster_pending_task_alert_slack
  infrastructure_ecs_cluster_pending_task_alert_opsgenie              = var.infrastructure_ecs_cluster_pending_task_alert_opsgenie
  enable_infrastructure_ecs_cluster_ecs_asg_diff_alert                = var.enable_infrastructure_ecs_cluster_ecs_asg_diff_alert && local.enable_infrastructure_ecs_cluster
  infrastructure_ecs_cluster_ecs_asg_diff_metric_lambda_log_retention = var.infrastructure_ecs_cluster_ecs_asg_diff_metric_lambda_log_retention
  infrastructure_ecs_cluster_ecs_asg_diff_alert_evaluation_periods    = var.infrastructure_ecs_cluster_ecs_asg_diff_alert_evaluation_periods
  infrastructure_ecs_cluster_ecs_asg_diff_alert_period                = var.infrastructure_ecs_cluster_ecs_asg_diff_alert_period
  infrastructure_ecs_cluster_ecs_asg_diff_alert_threshold             = var.infrastructure_ecs_cluster_ecs_asg_diff_alert_threshold
  infrastructure_ecs_cluster_ecs_asg_diff_alert_slack                 = var.infrastructure_ecs_cluster_ecs_asg_diff_alert_slack
  infrastructure_ecs_cluster_ecs_asg_diff_alert_opsgenie              = var.infrastructure_ecs_cluster_ecs_asg_diff_alert_opsgenie
  infrastructure_ecs_cluster_enable_debug_mode                        = var.infrastructure_ecs_cluster_enable_debug_mode
  infrastructure_ecs_cluster_enable_execute_command_logging           = var.infrastructure_ecs_cluster_enable_execute_command_logging
  infrastructure_ecs_cluster_wafs                                     = var.infrastructure_ecs_cluster_wafs
  infrastructure_ecs_cluster_enable_ssm_dhmc                          = local.enable_infrastructure_ecs_cluster ? data.external.ssm_dhmc_setting[0].result.setting_value != "$None" : false
  infrastructure_ecs_cluster_syslog_endpoint                          = var.infrastructure_ecs_cluster_syslog_endpoint
  infrastructure_ecs_cluster_syslog_port                              = local.infrastructure_ecs_cluster_syslog_endpoint != "" ? split(":", local.infrastructure_ecs_cluster_syslog_endpoint)[2] : null
  infrastructure_ecs_cluster_syslog_permitted_peer                    = var.infrastructure_ecs_cluster_syslog_permitted_peer
  infrastrucutre_ecs_cluster_logspout_enabled                         = local.enable_infrastructure_ecs_cluster && local.infrastructure_ecs_cluster_syslog_endpoint != ""
  infrastructure_ecs_cluster_user_data = base64encode(
    templatefile("ec2-userdata/ecs-instance.tpl", {
      docker_storage_volume_device_name = local.infrastructure_ecs_cluster_ebs_docker_storage_volume_device_name,
      ecs_cluster_name                  = local.infrastructure_ecs_cluster_name,
      dockerhub_token                   = local.infrastructure_dockerhub_token,
      dockerhub_email                   = local.infrastructure_dockerhub_email,
      docker_storage_size               = local.infrastructure_ecs_cluster_ebs_docker_storage_volume_size
      efs_id = local.enable_infrastructure_ecs_cluster_efs && (
        local.infrastructure_vpc_network_enable_private || local.infrastructure_vpc_network_enable_public
      ) ? aws_efs_file_system.infrastructure_ecs_cluster[0].id : "",
      region                = local.aws_region,
      efs_dirs              = join(" ", local.ecs_cluster_efs_directories),
      syslog_endpoint       = local.infrastructure_ecs_cluster_syslog_endpoint
      syslog_permitted_peer = local.infrastructure_ecs_cluster_syslog_permitted_peer
      log_debug_mode        = local.infrastructure_ecs_cluster_enable_debug_mode
    })
  )


  enable_infrastructure_ecs_cluster_efs        = var.enable_infrastructure_ecs_cluster_efs && local.infrastructure_vpc
  ecs_cluster_efs_performance_mode             = var.ecs_cluster_efs_performance_mode
  ecs_cluster_efs_throughput_mode              = var.ecs_cluster_efs_throughput_mode
  ecs_cluster_efs_infrequent_access_transition = var.ecs_cluster_efs_infrequent_access_transition
  ecs_cluster_efs_directories                  = var.ecs_cluster_efs_directories

  infrastructure_ecs_cluster_service_defaults = var.infrastructure_ecs_cluster_service_defaults
  infrastructure_ecs_cluster_services_keys    = length(var.infrastructure_ecs_cluster_services) > 0 ? keys(values(var.infrastructure_ecs_cluster_services)[0]) : []
  infrastructure_ecs_cluster_services = {
    for k, v in var.infrastructure_ecs_cluster_services : k => merge({
      for service_key in local.infrastructure_ecs_cluster_services_keys : service_key => try(coalesce(v[service_key], local.infrastructure_ecs_cluster_service_defaults[service_key]), null)
    })
  }
  infrastructure_ecs_cluster_services_alb_enable_global_accelerator = var.infrastructure_ecs_cluster_services_alb_enable_global_accelerator && length(local.infrastructure_ecs_cluster_services) > 0
  infrastructure_ecs_cluster_services_alb_ip_allow_list             = var.infrastructure_ecs_cluster_services_alb_ip_allow_list
  enable_infrastructure_ecs_cluster_services_alb_logs               = var.enable_infrastructure_ecs_cluster_services_alb_logs && length(local.infrastructure_ecs_cluster_services) > 0
  infrastructure_ecs_cluster_services_alb_logs_retention            = var.infrastructure_ecs_cluster_services_alb_logs_retention
  infrastructure_ecs_cluster_service_cloudfront_logs_glue_table_columns = [
    { name = "date", type = "date" },
    { name = "time", type = "string" },
    { name = "x-edge-location", type = "string" },
    { name = "bytes", type = "bigint" },
    { name = "client_ip", type = "string" },
    { name = "method", type = "string" },
    { name = "host", type = "string" },
    { name = "uri", type = "string" },
    { name = "status", type = "int" },
    { name = "referrer", type = "string" },
    { name = "user_agent", type = "string" },
    { name = "query_string", type = "string" },
    { name = "cookie", type = "string" },
    { name = "result_type", type = "string" },
    { name = "request_id", type = "string" },
    { name = "host_header", type = "string" },
    { name = "request_protocol", type = "string" },
    { name = "request_bytes", type = "string" },
    { name = "time_taken", type = "float" },
    { name = "x_forwarded_for", type = "string" },
    { name = "ssl_protocol", type = "string" },
    { name = "ssl_cipher", type = "string" },
    { name = "response_result_type", type = "string" },
    { name = "http_version", type = "string" },
    { name = "fle_status", type = "string" },
    { name = "fle_encrypted_fields", type = "int" },
    { name = "client_port", type = "int" },
    { name = "time_to_first_byte", type = "float" },
    { name = "x_edge_detailed_result_type", type = "string" },
    { name = "sc_content_type", type = "string" },
    { name = "sc_content_len", type = "bigint" },
    { name = "sc_range_start", type = "bigint" },
    { name = "sc_range_end", type = "bigint" },
  ]

  infrastructure_rds_defaults = var.infrastructure_rds_defaults
  infrastructure_rds_keys     = length(var.infrastructure_rds) > 0 ? keys(values(var.infrastructure_rds)[0]) : []
  infrastructure_rds = {
    for k, v in var.infrastructure_rds : k => merge({
      for rds_key in local.infrastructure_rds_keys : rds_key => try(coalesce(v[rds_key], local.infrastructure_rds_defaults[rds_key]), null)
    })
  }
  rds_engines = {
    "instance" = {
      "mysql"    = "mysql",
      "postgres" = "postgres"
    },
    "cluster" = {
      "mysql"    = "aurora-mysql",
      "postgres" = "aurora-postgresql"
    }
  }
  rds_licenses = {
    "mysql"    = "general-public-license"
    "postgres" = "postgresql-license"
  }
  rds_ports = {
    "mysql"    = 3306
    "postgres" = 5432
  }
  rds_s3_backups_container_entrypoint_file = {
    "mysql"    = "${path.root}/ecs-entrypoints/rds-s3-backups-mysql.txt.tpl"
    "postgres" = "${path.root}/ecs-entrypoints/rds-s3-backups-postgres.txt.tpl"
  }
  enable_infrastructure_rds_backup_to_s3          = var.enable_infrastructure_rds_backup_to_s3
  infrastructure_rds_backup_to_s3_cron_expression = var.infrastructure_rds_backup_to_s3_cron_expression
  infrastructure_rds_backup_to_s3_retention       = var.infrastructure_rds_backup_to_s3_retention
  enable_infrastructure_rds_tooling_ecs_cluster = anytrue([
    local.enable_infrastructure_rds_backup_to_s3,
  ])
  infrastructure_rds_tooling_ecs_cluster_name = "${local.resource_prefix}-infrastructure-rds-tooling"

  infrastructure_elasticache_defaults = var.infrastructure_elasticache_defaults
  infrastructure_elasticache_keys     = length(var.infrastructure_elasticache) > 0 ? keys(values(var.infrastructure_elasticache)[0]) : []
  infrastructure_elasticache = {
    for k, v in var.infrastructure_elasticache : k => merge({
      for elasticache_key in local.infrastructure_elasticache_keys : elasticache_key => try(coalesce(v[elasticache_key], local.infrastructure_elasticache_defaults[elasticache_key]), null)
    })
  }
  elasticache_ports = {
    "redis" = 6379
  }

  custom_route53_hosted_zones = var.custom_route53_hosted_zones

  custom_s3_buckets = var.custom_s3_buckets

  enable_cloudformatian_s3_template_store = var.enable_cloudformatian_s3_template_store != null ? var.enable_cloudformatian_s3_template_store : false
  custom_cloudformation_stacks            = var.custom_cloudformation_stacks

  s3_object_presign = local.enable_cloudformatian_s3_template_store ? toset([
    for k, v in local.custom_cloudformation_stacks : "${aws_s3_bucket.cloudformation_custom_stack_template_store[0].id}/${v["s3_template_store_key"]}" if v["s3_template_store_key"] != null
  ]) : []

  default_tags = {
    Project        = local.project_name,
    Infrastructure = local.infrastructure_name,
    Environment    = local.environment,
    Prefix         = local.resource_prefix,
  }
}
