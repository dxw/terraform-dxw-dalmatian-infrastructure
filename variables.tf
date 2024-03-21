variable "project_name" {
  description = "Project name to be used as a prefix for all resources"
  type        = string
}

variable "infrastructure_name" {
  description = "The infrastructure name to be used as part of the resource prefix"
  type        = string
}

variable "environment" {
  description = "The environment name to be used as part of the resource prefix"
  type        = string
}

variable "aws_region" {
  description = "AWS region in which to launch resources"
  type        = string
}

variable "infrastructure_dockerhub_email" {
  description = "Dockerhub email"
  type        = string
}

variable "infrastructure_dockerhub_username" {
  description = "Dockerhub username"
  type        = string
}

variable "infrastructure_dockerhub_token" {
  description = "Dockerhub token which has permissions to pull images"
  type        = string
}

variable "infrastructure_kms_encryption" {
  description = "Enable infrastructure KMS encryption. This will create a single KMS key to be used across all resources that support KMS encryption."
  type        = bool
}

variable "infrastructure_logging_bucket_retention" {
  description = "Retention in days for the infrasrtucture S3 logs. This is for the default S3 logs bucket, where all AWS service logs will be delivered"
  type        = number
}

variable "infrastructure_vpc" {
  description = "Enable infrastructure VPC"
  type        = bool
}

variable "infrastructure_vpc_cidr_block" {
  description = "Infrastructure VPC CIDR block"
  type        = string
}

variable "infrastructure_vpc_enable_dns_support" {
  description = "Enable DNS support on infrastructure VPC"
  type        = bool
}

variable "infrastructure_vpc_enable_dns_hostnames" {
  description = "Enable DNS hostnames on infrastructure VPC"
  type        = bool
}

variable "infrastructure_vpc_instance_tenancy" {
  description = "Infrastructure VPC instance tenancy"
  type        = string
}

variable "infrastructure_vpc_enable_network_address_usage_metrics" {
  description = "Enable network address usage metrics on infrastructure VPC"
  type        = bool
}

variable "infrastructure_vpc_assign_generated_ipv6_cidr_block" {
  description = "Assign generated IPv6 CIDR block on infrastructure VPC"
  type        = bool
}

variable "infrastructure_vpc_flow_logs_cloudwatch_logs" {
  description = "Enable VPC logs on infrastructure VPC to CloudWatch Logs"
  type        = bool
}

variable "infrastructure_vpc_flow_logs_s3_with_athena" {
  description = "Enable VPC flow logs in infrastructure VPC to the S3 logs bucket. A compatible Glue table/database and Athena workgroup will also be created to allow querying the logs."
  type        = bool
}

variable "infrastructure_vpc_flow_logs_retention" {
  description = "VPC flow logs retention in days"
  type        = number
}

variable "infrastructure_vpc_flow_logs_traffic_type" {
  description = "Infrastructure VPC flow logs traffic type"
  type        = string
}

variable "infrastructure_vpc_flow_logs_s3_key_prefix" {
  description = "Flow Logs by default will go into the infrastructure S3 logs bucket. This is the key prefix used to isolate them from other logs"
  type        = string
}

variable "infrastructure_vpc_network_enable_public" {
  description = "Enable public networking on Infrastructure VPC. This will create subnets with a route to an Internet Gateway"
  type        = bool
}

variable "infrastructure_vpc_network_enable_private" {
  description = "Enable private networking on Infrastructure VPC. This will create subnets with a route to a NAT Gateway (If Public networking has been enabled)"
  type        = bool
}

variable "infrastructure_vpc_network_availability_zones" {
  description = "A list of availability zone characters (eg. [\"a\", \"b\", \"c\"])"
  type        = list(string)
}

variable "infrastructure_vpc_network_acl_egress_lockdown_private" {
  description = "Creates a network ACL for the private subnets which blocks all egress traffic, permitting only the ports required for resources deployed by this module and custom rules."
  type        = bool
}

variable "infrastructure_vpc_network_acl_egress_custom_rules_private" {
  description = "Infrastructure vpc egress custom rules for the private subnets. These will be evaluated before any automatically added rules."
  type = list(object({
    protocol        = string
    from_port       = number
    to_port         = number
    action          = string
    cidr_block      = string
    ipv6_cidr_block = optional(string, null)
    icmp_type       = optional(number, null)
    icmp_code       = optional(number, null)
  }))
}

variable "infrastructure_vpc_network_acl_egress_lockdown_public" {
  description = "Creates a network ACL for the public subnets which blocks all egress traffic, permitting only the ports required for resources deployed by this module and custom rules."
  type        = bool
}

variable "infrastructure_vpc_network_acl_egress_custom_rules_public" {
  description = "Infrastructure vpc egress custom rules for the public subnets. These will be evaluated before any automatically added rules."
  type = list(object({
    protocol        = string
    from_port       = number
    to_port         = number
    action          = string
    cidr_block      = string
    ipv6_cidr_block = optional(string, null)
    icmp_type       = optional(number, null)
    icmp_code       = optional(number, null)
  }))
}

variable "infrastructure_vpc_network_acl_ingress_lockdown_private" {
  description = "Creates a network ACL for the private subnets which blocks all ingress traffic, permitting only the ports required for resources deployed by this module and custom rules."
  type        = bool
}

variable "infrastructure_vpc_network_acl_ingress_custom_rules_private" {
  description = "Infrastructure vpc ingress custom rules for the private subnets. These will be evaluated before any automatically added rules."
  type = list(object({
    protocol        = string
    from_port       = number
    to_port         = number
    action          = string
    cidr_block      = string
    ipv6_cidr_block = optional(string, null)
    icmp_type       = optional(number, null)
    icmp_code       = optional(number, null)
  }))
}

variable "infrastructure_vpc_network_acl_ingress_lockdown_public" {
  description = "Creates a network ACL for the public subnets which blocks all ingress traffic, permitting only the ports required for resources deployed by this module and custom rules."
  type        = bool
}

variable "infrastructure_vpc_network_acl_ingress_custom_rules_public" {
  description = "Infrastructure vpc ingress custom rules for the public subnets. These will be evaluated before any automatically added rules."
  type = list(object({
    protocol        = string
    from_port       = number
    to_port         = number
    action          = string
    cidr_block      = string
    ipv6_cidr_block = optional(string, null)
    icmp_type       = optional(number, null)
    icmp_code       = optional(number, null)
  }))
}

variable "route53_root_hosted_zone_domain_name" {
  description = "Route53 Hosted Zone in which to delegate Infrastructure Route53 Hosted Zones."
  type        = string
}

variable "aws_profile_name_route53_root" {
  description = "AWS Profile name which is configured for the account in which the root Route53 Hosted Zone exists."
  type        = string
}

variable "enable_infrastructure_route53_hosted_zone" {
  description = "Creates a Route53 hosted zone, where DNS records will be created for resources launched within this module."
  type        = bool
}

variable "enable_infrastructure_ecs_cluster" {
  description = "Enable creation of infrastructure ECS cluster, to place ECS services"
  type        = bool
}

variable "infrastructure_ecs_cluster_ami_version" {
  description = "AMI version for ECS cluster instances (amzn2-ami-ecs-hvm-<version>)"
  type        = string
}

variable "infrastructure_ecs_cluster_ebs_docker_storage_volume_size" {
  description = "Size of EBS volume for Docker storage on the infrastructure ECS instances"
  type        = number
}

variable "infrastructure_ecs_cluster_ebs_docker_storage_volume_type" {
  description = "Type of EBS volume for Docker storage on the infrastructure ECS instances (eg. gp3)"
  type        = string
}

variable "infrastructure_ecs_cluster_publicly_avaialble" {
  description = "Conditionally launch the ECS cluster EC2 instances into the Public subnet"
  type        = bool
}

variable "infrastructure_ecs_cluster_instance_type" {
  description = "The instance type for EC2 instances launched in the ECS cluster"
  type        = string
}

variable "infrastructure_ecs_cluster_termination_timeout" {
  description = "The timeout for the terminiation lifecycle hook"
  type        = number
}

variable "infrastructure_ecs_cluster_draining_lambda_enabled" {
  description = "Enable the Lambda which ensures all containers have drained before terminating ECS cluster instances"
  type        = bool
}

variable "infrastructure_ecs_cluster_draining_lambda_log_retention" {
  description = "Log retention for the ECS cluster draining Lambda"
  type        = number
}

variable "infrastructure_ecs_cluster_min_size" {
  description = "Minimum number of instances for the ECS cluster"
  type        = number
}

variable "infrastructure_ecs_cluster_max_size" {
  description = "Maximum number of instances for the ECS cluster"
  type        = number
}

variable "infrastructure_ecs_cluster_max_instance_lifetime" {
  description = "Maximum lifetime in seconds of an instance within the ECS cluster"
  type        = number
}

variable "infrastructure_ecs_cluster_autoscaling_time_based_max" {
  description = "List of cron expressions to scale the ECS cluster to the configured max size"
  type        = list(string)
}

variable "infrastructure_ecs_cluster_autoscaling_time_based_min" {
  description = "List of cron expressions to scale the ECS cluster to the configured min size"
  type        = list(string)
}

variable "infrastructure_ecs_cluster_autoscaling_time_based_custom" {
  description = "List of objects with min/max sizes and cron expressions to scale the ECS cluster. Min size will be used as desired."
  type = list(
    object({
      cron = string
      min  = number
      max  = number
    })
  )
}

variable "infrastructure_ecs_cluster_service_defaults" {
  description = "Default values for ECS Cluster Services"
  type = object({
    github_v1_source                              = optional(bool, null)
    github_v1_oauth_token                         = optional(string, null)
    codestar_connection_arn                       = optional(string, null)
    github_owner                                  = optional(string, null)
    github_repo                                   = optional(string, null)
    github_track_revision                         = optional(string, null)
    buildspec                                     = optional(string, null)
    buildspec_from_github_repo                    = optional(bool, null)
    ecr_scan_target_sns_topic_arn                 = optional(string, null)
    deployment_type                               = optional(string, null)
    enable_cloudwatch_logs                        = optional(bool, null)
    cloudwatch_logs_retention                     = optional(number, null)
    enable_execute_command                        = optional(bool, null)
    deregistration_delay                          = optional(number, null)
    container_entrypoint                          = optional(list(string), null)
    container_port                                = optional(number, null)
    container_volumes                             = optional(list(map(string)), null)
    container_extra_hosts                         = optional(list(map(string)), null)
    container_count                               = optional(number, null)
    container_heath_check_path                    = optional(string, null)
    container_heath_grace_period                  = optional(number, null)
    enable_cloudfront                             = optional(bool, null)
    cloudfront_access_logging_enabled             = optional(bool, null)
    cloudfront_bypass_protection_enabled          = optional(bool, null)
    cloudfront_bypass_protection_excluded_domains = optional(list(string), null)
    cloudfront_origin_shield_enabled              = optional(bool, null)
    cloudfront_managed_cache_policy               = optional(string, null)
    cloudfront_managed_origin_request_policy      = optional(string, null)
    cloudfront_managed_response_headers_policy    = optional(string, null)
  })
}

variable "infrastructure_ecs_cluster_services" {
  description = <<EOT
    Map of ECS Cluster Services (The key will be the service name). Values in here will override `infrastructure_ecs_cluster_service_defaults` values if set."
    {
      service-name = {
        github_v1_source: Conditionally use GitHubV1 for the CodePipeline source (CodeStar will be used by default)
        github_v1_oauth_token: If `github_v1_source` is set to true, provide the GitHub OAuthToken here
        codestar_connection_arn: The CodeStar Connection ARN to use in the CodePipeline source
        github_owner: The GitHub Owner of the repository to be pulled by the CodePipeline source
        github_repo: The GitHub repo name to be pulled by the CodePipeline source
        github_track_revision: The branch/revision of the GitHub repository to be pulled by the CodePipeline source
        buildspec: The filename of the buildspec to use for the CodePipeline build phase, stored within the 'codepipeline buildspec store' S3 bucket
        buildspec_from_github_repo: Conditionally use the 'buildspec' filename stored within the GitHub repo as the buildspec
        ecr_scan_target_sns_topic_arn: An SNS topic ARN to publish ECR scan results to
        deployment_type: The service deployment type - Can be one of 'rolling' or 'blue-green'
        enable_cloudwatch_logs: Conditionally enable cloudwatch logs for the service
        cloudwatch_logs_retention: CloudWatch log retention in days
        enable_execute_command: Enable Amazon ECS Exec to directly interact with containers
        deregistration_delay: Amount time for Elastic Load Balancing to wait before changing the state of a deregistering target from draining to unused
        container_entrypoint: The container entrypoint
        container_port: The service container port
        container_volumes: List of maps containing volume mappings eg. [ { "name" = "my-volume", "host_path" = "/mnt/efs/my-dir", "container_path" = "/mnt/my-dir" } ]
        container_extra_hosts: List of maps containing extra hosts eg. [ { "hostname" = "my.host", "ip_address" = "10.1.2.3" } ]
        container_count: Number of containers to launch for the service
        container_heath_check_path: Destination for the health check request
        container_heath_grace_period: Seconds to ignore failing load balancer health checks on newly instantiated tasks to prevent premature shutdown
        enable_cloudfront: Enable cloadfront for the service
        cloudfront_access_logging_enabled: Enable access logging for the distribution to the infrastructure S3 logs bucket
        cloudfront_bypass_protection_enabled: This adds a secret header at the CloudFront level, which is then checked by the ALB listener rules. Requests are only forwarded if the header matches, preventing requests going directly to the ALB.
        cloudfront_bypass_protection_excluded_domains: A list of domains to exclude from the bypass protection
        cloudfront_origin_shield_enabled: Enable CloudFront Origin Shield
        cloudfront_managed_cache_policy: Conditionally specify a CloudFront Managed Cache Policy for the distribution
        cloudfront_managed_origin_request_policy: Conditionally specify a CloudFront Managed Origin Request Policy for the distribution
        cloudfront_managed_response_headers_policy: Conditionally specify a CloudFront Managed Response Headers Policy for the distribution
      }
    }
  EOT
  type = map(object({
    github_v1_source                              = optional(bool, null)
    github_v1_oauth_token                         = optional(string, null)
    codestar_connection_arn                       = optional(string, null)
    github_owner                                  = optional(string, null)
    github_repo                                   = optional(string, null)
    github_track_revision                         = optional(string, null)
    buildspec                                     = optional(string, null)
    buildspec_from_github_repo                    = optional(bool, null)
    ecr_scan_target_sns_topic_arn                 = optional(string, null)
    deployment_type                               = optional(string, null)
    enable_cloudwatch_logs                        = optional(bool, null)
    cloudwatch_logs_retention                     = optional(number, null)
    enable_execute_command                        = optional(bool, null)
    deregistration_delay                          = optional(number, null)
    container_entrypoint                          = optional(list(string), null)
    container_port                                = optional(number, null)
    container_volumes                             = optional(list(map(string)), null)
    container_extra_hosts                         = optional(list(map(string)), null)
    container_count                               = optional(number, null)
    container_heath_check_path                    = optional(string, null)
    container_heath_grace_period                  = optional(number, null)
    enable_cloudfront                             = optional(bool, null)
    cloudfront_access_logging_enabled             = optional(bool, null)
    cloudfront_bypass_protection_enabled          = optional(bool, null)
    cloudfront_bypass_protection_excluded_domains = optional(list(string), null)
    cloudfront_origin_shield_enabled              = optional(bool, null)
    cloudfront_managed_cache_policy               = optional(string, null)
    cloudfront_managed_origin_request_policy      = optional(string, null)
    cloudfront_managed_response_headers_policy    = optional(string, null)
  }))
}

variable "infrastructure_rds_defaults" {
  description = "Default values for RDSs"
  type = object({
    type                              = optional(string, null)
    engine                            = optional(string, null)
    engine_version                    = optional(string, null)
    parameters                        = optional(map(string), null)
    instance_class                    = optional(string, null)
    allocated_storage                 = optional(number, null)
    storage_type                      = optional(string, null)
    iops                              = optional(number, null)
    storage_throughput                = optional(number, null)
    multi_az                          = optional(bool, null)
    monitoring_interval               = optional(number, null)
    cloudwatch_logs_export_types      = optional(list(string), null)
    cluster_instance_count            = optional(number, null)
    cluster_serverlessv2_min_capacity = optional(number, null)
    cluster_serverlessv2_max_capacity = optional(number, null)
  })
}

variable "infrastructure_rds" {
  description = <<EOT
    Map of RDSs (The key will be the rds name). Values in here will override `infrastructure_rds_defaults` values if set."
    {
      rds-name = {
        type: Choose either `instance` for RDS instance, or `cluster` for RDS Aurora
        engine: RDS engine (Either `mysql` or `postgres`)
        engine_version: RDS Engine version (Specify the major version only, to prevent terraform attempting to downgrade minor versions)
        parameters: Map of Parameters for the DB parameter group ({ parameter-name = parameter-value, ... })
        instance_class: RDS instance class
        allocated_storage: RDS allocated storage
        storage_type: RDS storage type
        iops: RDS iops (When `type` is `instance`, this is only required for storage type of `io1` or `gp3` - When `cluster`, this must be a multiple between .5 and 50 of the storage amount for the DB cluster.`)
        storage_throughput: RDS storage throughput (Only required when `storage_type` is `gp3`. Only applicable for `type` of `instance`)
        multi_az: Enable Multi-AZ RDS (Not applicable for `type` of `cluster`. For `cluster - set `storage_type`, `allocated_storage`, `iops` and `instance_class`)
        monitoring_interval: The interval, in seconds, between points when Enhanced Monitoring metrics are collected for the DB instance. Valid Values: 0, 1, 5, 10, 15, 30, 60.
        cloudwatch_logs_export_types: List of log types to enable for exporting to CloudWatch Logs. See `EnableCloudwatchLogsExports.member.N` (https://docs.aws.amazon.com/AmazonRDS/latest/APIReference/API_CreateDBInstance.html) for valid values.
        cluster_instance_count: Number of instances to launch within the Aurora DB cluster
        cluster_serverlessv2_min_capacity: Minimum capacity for an Aurora DB cluster
        cluster_serverlessv2_max_capacity: Maximum capacity for an Aurora DB cluster
      }
    }
  EOT
  type = map(object({
    type                              = optional(string, null)
    engine                            = optional(string, null)
    engine_version                    = optional(string, null)
    parameters                        = optional(map(string), null)
    instance_class                    = optional(string, null)
    allocated_storage                 = optional(number, null)
    storage_type                      = optional(string, null)
    iops                              = optional(number, null)
    storage_throughput                = optional(number, null)
    multi_az                          = optional(bool, null)
    monitoring_interval               = optional(number, null)
    cloudwatch_logs_export_types      = optional(list(string), null)
    cluster_instance_count            = optional(number, null)
    cluster_serverlessv2_min_capacity = optional(number, null)
    cluster_serverlessv2_max_capacity = optional(number, null)
  }))
}

variable "custom_route53_hosted_zones" {
  description = <<EOT
    Map of Route53 Hosted Zone configurations to create
    {
      example.com = {
        ns_records: Map of NS records to create ({ "domain.example.com"  = { values = ["ns1.example.com", "ns2.example.com"], ttl = 300 })
        a_records: Map of A records to create ({ "domain.example.com"  = { values = ["1.2.3.4", "5.6.7.8"], ttl = 300 })
        alias_records: Map of ALIAS records to create ({ "domain.example.com"  = { value = "example.cloudfront.com", zone_id = "Z2FDTNDATAQYW2" })
        cname_records: Map of CNAME records to create ({ "domain.example.com"  = { values = ["external1.example.com", "external2.example.com"], ttl = 60 })
        mx_records: Map of MX records to create ({ "example.com"  = { values = ["1 mail.example.com", "5 mail2.example.com"], ttl = 60 })
        txt_records: Map of TXT records to create ({ "example.com"  = { values = ["v=spf1 include:spf.example.com -all"], ttl = 60 })
      }
    }
  EOT
  type = map(object({
    ns_records = optional(map(object({
      values = list(string)
      ttl    = optional(number, 300)
    })), null)
    a_records = optional(map(object({
      values = list(string)
      ttl    = optional(number, 300)
    })), null)
    alias_records = optional(map(object({
      value   = string
      zone_id = string
    })), null)
    cname_records = optional(map(object({
      values = list(string)
      ttl    = optional(number, 300)
    })), null)
    mx_records = optional(map(object({
      values = list(string)
      ttl    = optional(number, 300)
    })), null)
    txt_records = optional(map(object({
      values = list(string)
      ttl    = optional(number, 300)
    })), null)
  }))
}

variable "infrastructure_ecs_cluster_services_alb_enable_global_accelerator" {
  description = "Enable Global Accelerator (GA) for the infrastructure ECS cluster services ALB. If `cloudfront_bypass_protection_enabled` is set for a service, any domain pointing towards the GA must be added to the `cloudfront_bypass_protection_excluded_domains` list. It is recommended that the GA only be used for apex domains that redirect to the domain associated with CloudFront. Ideally, apex domains would use an ALIAS record pointing towards the CloudFront distribution."
  type        = bool
}

variable "infrastructure_ecs_cluster_services_alb_ip_allow_list" {
  description = "IP allow list for ingress traffic to the infrastructure ECS cluster services ALB"
  type        = list(string)
}

variable "enable_infrastructure_ecs_cluster_services_alb_logs" {
  description = "Enable Infrastructure ECS cluster services ALB logs"
  type        = bool
}

variable "infrastructure_ecs_cluster_services_alb_logs_retention" {
  description = "Retention in days for the infrasrtucture ecs cluster ALB logs"
  type        = number
}

variable "enable_infrastructure_ecs_cluster_efs" {
  description = "Conditionally create and mount EFS to the ECS cluster instances"
  type        = bool
}

variable "ecs_cluster_efs_performance_mode" {
  description = "ECS cluser EFS performance mode"
  type        = string
}

variable "ecs_cluster_efs_throughput_mode" {
  description = "ECS cluser EFS throughput mode"
  type        = string
}

variable "ecs_cluster_efs_infrequent_access_transition" {
  description = "ECS cluser EFS IA transiton in days. Set to 0 to disable IA transition."
  type        = number
}

variable "ecs_cluster_efs_directories" {
  description = "ECS cluster EFS directories to create"
  type        = list(string)
}

variable "custom_s3_buckets" {
  description = <<EOT
    Map of S3 buckets to create, and conditionally serve via CloudFront. The S3 configuration will follow AWS best practices (eg. Private, ACLS disabled, SSE, Versioning, Logging). The bucket must be emptied before attempting deletion/destruction."
    {
      bucket-name = {
        create_dedicated_kms_key: Conditionally create a KMS key specifically for this bucket's server side encryption (rather than using the Infrastructure's KMS key). It's recommended to use this if the S3 bucket will be accessed from external AWS accounts.
        transition_to_ia_days: Conditionally transition objects to 'Standard Infrequent Access' storage in N days
        transition_to_glacier_days: Conditionally transition objects to 'Glacier' storage in N days
        cloudfront_dedicated_distribution: Conditionally create a CloudFront distribution to serve objects from the S3 bucket.
        cloudfront_s3_root: Sets the S3 document root when being served from CloudFront. By default this will be '/'. If `cloudfront_infrastructure_ecs_cluster_service_path` has been set, this helps by modifying the request from `/sub-directory-path` to `/` by use of a CloudFront function.
        cloudfront_infrastructure_ecs_cluster_service: Conditionally create an Origin on a CloudFront distribution that is serving the given Infrastructure ECS Cluster Service name
        cloudfront_infrastructure_ecs_cluster_service_path: If `cloudfront_infrastructure_ecs_cluster_service`, set this to the path that objects will be served from.
      }
    }
  EOT
  type = map(object({
    create_dedicated_kms_key                           = optional(bool, null)
    transition_to_ia_days                              = optional(number, null)
    transition_to_glacier_days                         = optional(number, null)
    cloudfront_dedicated_distribution                  = optional(bool, null)
    cloudfront_s3_root                                 = optional(string, null)
    cloudfront_infrastructure_ecs_cluster_service      = optional(string, null)
    cloudfront_infrastructure_ecs_cluster_service_path = optional(string, null)
  }))
}
