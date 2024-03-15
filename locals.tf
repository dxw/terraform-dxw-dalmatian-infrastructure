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
    local.infrastructure_vpc_flow_logs_s3_with_athena ||
    length(local.infrastructure_ecs_cluster_services) != 0
  )
  logs_bucket_source_arns = concat(
    local.infrastructure_vpc_flow_logs_s3_with_athena ? ["arn:aws:logs:${local.aws_region}:${local.aws_account_id}:*"] : [],
    length(local.infrastructure_ecs_cluster_services) != 0 ? [aws_s3_bucket.infrastructure_ecs_cluster_service_build_pipeline_artifact_store[0].arn] : []
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
  infrastructure_ecs_cluster_instance_type                         = var.infrastructure_ecs_cluster_instance_type
  infrastructure_ecs_cluster_termination_timeout                   = var.infrastructure_ecs_cluster_termination_timeout
  infrastructure_ecs_cluster_draining_lambda_enabled               = var.infrastructure_ecs_cluster_draining_lambda_enabled && local.enable_infrastructure_ecs_cluster
  infrastructure_ecs_cluster_draining_lambda_log_retention         = var.infrastructure_ecs_cluster_draining_lambda_log_retention
  infrastructure_ecs_cluster_termination_sns_topic_name            = "${local.resource_prefix}-infrastructure-ecs-cluster-termination"
  infrastructure_ecs_cluster_min_size                              = var.infrastructure_ecs_cluster_min_size
  infrastructure_ecs_cluster_max_size                              = var.infrastructure_ecs_cluster_max_size
  infrastructure_ecs_cluster_max_instance_lifetime                 = var.infrastructure_ecs_cluster_max_instance_lifetime
  infrastructure_ecs_cluster_autoscaling_time_based_max            = toset(var.infrastructure_ecs_cluster_autoscaling_time_based_max)
  infrastructure_ecs_cluster_autoscaling_time_based_min            = toset(var.infrastructure_ecs_cluster_autoscaling_time_based_min)
  infrastructure_ecs_cluster_autoscaling_time_based_custom = {
    for custom in toset(var.infrastructure_ecs_cluster_autoscaling_time_based_custom) : "${custom["min"]}-${custom["max"]} ${custom["cron"]}" => custom
  }
  infrastructure_ecs_cluster_enable_ssm_dhmc = local.enable_infrastructure_ecs_cluster ? data.external.ssm_dhmc_setting[0].result.setting_value != "$None" : ""
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
      region   = local.aws_region,
      efs_dirs = join(" ", local.ecs_cluster_efs_directories)
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

  infrastructure_rds_defaults = var.infrastructure_rds_defaults
  infrastructure_rds_keys     = length(var.infrastructure_rds) > 0 ? keys(values(var.infrastructure_rds)[0]) : []
  infrastructure_rds = {
    for k, v in var.infrastructure_rds : k => merge({
      for rds_key in local.infrastructure_rds_keys : rds_key => try(coalesce(v[rds_key], local.infrastructure_rds_defaults[rds_key]), null)
    })
  }
  infrastructure_rds_backups_enabled = {
    for k, v in local.infrastructure_rds : k => v if v["daily_backup_to_s3"] == true
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

  custom_route53_hosted_zones = var.custom_route53_hosted_zones

  default_tags = {
    Project        = local.project_name,
    Infrastructure = local.infrastructure_name,
    Environment    = local.environment,
    Prefix         = local.resource_prefix,
  }
}
