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

variable "infrastructure_datadog_api_key" {
  description = "Datadog API key"
  type        = string
  sensitive   = true
}

variable "infrastructure_datadog_app_key" {
  description = "Datadog App key"
  type        = string
  sensitive   = true
}

variable "infrastructure_datadog_region" {
  description = "Datadog region"
  type        = string
}

variable "enable_infrastructure_ecs_cluster_datadog_agent" {
  description = "Conditionally launch Datadog agent containers on the ECS cluster"
  type        = bool
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

variable "infrastructure_kms_key_policy_statements" {
  description = "Additional KMS key policy statements for the Infrastructure KMS key"
  type        = string
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

variable "enable_infrastructure_vpc_transfer_s3_bucket" {
  description = "Enable VPC transfer S3 bucket. This allows uploading/downloading files from resources within the infrastructure VPC"
  type        = bool
}

variable "infrastructure_vpc_transfer_s3_bucket_access_vpc_ids" {
  description = "Additional VPC ids which are allowed to access the transfer S3 bucket"
  type        = list(string)
}

variable "enable_infrastructure_bastion_host" {
  description = "Enable Infrastructure Bastion host. This launches a t3.micro AL2023 instance within the VPC that can be accessed via Session Manager"
  type        = bool
}

variable "infrastructure_bastion_host_custom_security_group_rules" {
  description = "Map of custom security group rules to add to the Infrastructure EC2 Bastion Host security group (eg. { rule-name = {type = \"egress\", ... }  })"
  type = map(object({
    description              = string
    type                     = string
    from_port                = number
    to_port                  = number
    protocol                 = string
    source_security_group_id = optional(string, "")
    cidr_blocks              = optional(list(string), [])
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

variable "infrastructure_ecs_cluster_container_insights" {
  description = "Enable Container Insights for the Infrastructure ECS Cluster"
  type        = string
  default     = "enabled"
  validation {
    condition     = contains(["disabled", "enabled", "enhanced"], var.infrastructure_ecs_cluster_container_insights)
    error_message = "Valid values for infrastructure_ecs_cluster_container_insights are 'disabled', 'enabled', and 'enhanced'."
  }
}

variable "infrastructure_utilities_ecs_cluster_container_insights" {
  description = "Enable Container Insights for the Utilities ECS Cluster"
  type        = string
  default     = "enabled"
  validation {
    condition     = contains(["disabled", "enabled", "enhanced"], var.infrastructure_utilities_ecs_cluster_container_insights)
    error_message = "Valid values for infrastructure_utilities_ecs_cluster_container_insights are 'disabled', 'enabled', and 'enhanced'."
  }
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

variable "infrastructure_ecs_cluster_custom_security_group_rules" {
  description = "Map of custom security group rules to add to the ECS Cluster security group (eg. { rule-name = {type = \"egress\", ... }  })"
  type = map(object({
    description              = string
    type                     = string
    from_port                = number
    to_port                  = number
    protocol                 = string
    source_security_group_id = optional(string, "")
    cidr_blocks              = optional(list(string), [])
  }))
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

variable "infrastructure_ecs_cluster_instance_refresh_lambda_schedule_expression" {
  description = "Conditionally launch a lambda to trigger an instance refresh on the ECS ASG, provided a schedule expression"
  type        = string
}

variable "infrastructure_ecs_cluster_instance_refresh_lambda_log_retention" {
  description = "Log retention for the ECS cluster instance refresh lambda"
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

variable "infrastructure_ecs_cluster_capacity_provider" {
  description = <<EOT
    Create an ECS capacity provider with managed scaling over the cluster's Auto Scaling Group and run every service in the cluster through it, so instances are added and removed as the services' reserved memory and CPU require. null (the default) leaves the cluster on the EC2 launch type. ECS cannot move a service from the EC2 launch type to a capacity provider in place, so enabling (or later disabling) this on a cluster that already has services makes Terraform replace every service in the cluster: each is destroyed and recreated in the same apply, which is a short outage for that cluster only. The apply also starts a rolling instance refresh, because the AmazonECSManaged tag it adds to the ASG is a refresh trigger. A recreated blue/green service attaches to its blue target group, so before the apply confirm the listener rule forwards to blue (or run a deployment straight after), otherwise traffic goes to the empty green group until the next deployment. Requires infrastructure_ecs_cluster_draining_lambda_enabled.
    {
      target_capacity: Percentage of reserved capacity ECS keeps the cluster at; below 100 keeps spare instances for scale-out (default 90)
      minimum_scaling_step_size: Fewest instances added or removed per scaling action (default 1)
      maximum_scaling_step_size: Most instances added or removed per scaling action (default 2)
      instance_warmup_period: Seconds a new instance takes before it counts towards capacity (default 300)
    }
  EOT
  type = object({
    target_capacity           = optional(number, 90)
    minimum_scaling_step_size = optional(number, 1)
    maximum_scaling_step_size = optional(number, 2)
    instance_warmup_period    = optional(number, 300)
  })
  default = null
  validation {
    condition     = var.infrastructure_ecs_cluster_capacity_provider == null || var.infrastructure_ecs_cluster_capacity_provider.minimum_scaling_step_size <= var.infrastructure_ecs_cluster_capacity_provider.maximum_scaling_step_size
    error_message = "infrastructure_ecs_cluster_capacity_provider.minimum_scaling_step_size must not exceed maximum_scaling_step_size."
  }
}

variable "enable_infrastructure_ecs_cluster_asg_cpu_alert" {
  description = "Enable a CPU alert for the ECS cluster's Autoscaling Group"
  type        = bool
}

variable "infrastructure_ecs_cluster_asg_cpu_alert_evaluation_periods" {
  description = "Evaluation periods for the ECS cluster's Autoscaling Group CPU alert"
  type        = number
}

variable "infrastructure_ecs_cluster_asg_cpu_alert_period" {
  description = "Period (in secods) for the ECS cluster's Autoscaling Group CPU alert"
  type        = number
}

variable "infrastructure_ecs_cluster_asg_cpu_alert_threshold" {
  description = "Threshold (CPU%) for the ECS cluster's Autoscaling Group CPU alert"
  type        = number
}

variable "infrastructure_ecs_cluster_asg_cpu_alert_slack" {
  description = "Enable Slack alerts for the ECS cluster's Autoscaling Group CPU alert"
  type        = bool
}

variable "infrastructure_ecs_cluster_asg_cpu_alert_opsgenie" {
  description = "Enable Opsgenie alerts for the ECS cluster's Autoscaling Group CPU alert"
  type        = bool
}

variable "enable_infrastructure_ecs_cluster_pending_task_alert" {
  description = "Enable the ECS Cluster pending task alert"
  type        = bool
}

variable "infrastructure_ecs_cluster_pending_task_metric_lambda_log_retention" {
  description = "Log retention for the ECS cluster pending task metric Lambda"
  type        = number
}

variable "infrastructure_ecs_cluster_pending_task_alert_evaluation_periods" {
  description = "Evaluation periods for the ECS cluster's Pending Task alert"
  type        = number
}

variable "infrastructure_ecs_cluster_pending_task_alert_period" {
  description = "Period (in secods) for the ECS cluster's Pending Task alert"
  type        = number
}

variable "infrastructure_ecs_cluster_pending_task_alert_threshold" {
  description = "Threshold (Number of pending tasks) for the ECS cluster's Pending Task alert"
  type        = number
}

variable "infrastructure_ecs_cluster_pending_task_alert_slack" {
  description = "Enable Slack alerts for the ECS cluster's Pending Task alert"
  type        = bool
}

variable "infrastructure_ecs_cluster_pending_task_alert_opsgenie" {
  description = "Enable Opsgenie alerts for the ECS cluster's Pending Task alert"
  type        = bool
}

variable "enable_infrastructure_ecs_cluster_ecs_asg_diff_alert" {
  description = "Enable the ECS Cluster Container Instance / ASG instance diff alert"
  type        = bool
}

variable "infrastructure_ecs_cluster_ecs_asg_diff_metric_lambda_log_retention" {
  description = "Log retention for the ECS cluster Container Instance / ASG instance diff metric Lambda"
  type        = number
}

variable "infrastructure_ecs_cluster_ecs_asg_diff_alert_evaluation_periods" {
  description = "Evaluation periods for the ECS cluster's Container Instance / ASG instance diff alert"
  type        = number
}

variable "infrastructure_ecs_cluster_ecs_asg_diff_alert_period" {
  description = "Period (in secods) for the ECS cluster's Container Instance / ASG instance diff alert"
  type        = number
}

variable "infrastructure_ecs_cluster_ecs_asg_diff_alert_threshold" {
  description = "Threshold (Number of pending tasks) for the ECS cluster's Container Instance / ASG instance diff alert"
  type        = number
}

variable "infrastructure_ecs_cluster_ecs_asg_diff_alert_slack" {
  description = "Enable Slack alerts for the ECS cluster's Container Instance / ASG instance diff alert"
  type        = bool
}

variable "infrastructure_ecs_cluster_ecs_asg_diff_alert_opsgenie" {
  description = "Enable Opsgenie alerts for the ECS cluster's Container Instance / ASG instance diff alert"
  type        = bool
}

variable "infrastructure_ecs_cluster_service_pipeline_slack_notifications" {
  description = "Send the ECS service pipelines' execution state changes (started, succeeded, failed, stopped, superseded) to the account's CloudWatch Slack alerts SNS topic. Requires the account-bootstrap CloudWatch Slack alerts to be enabled in this account."
  type        = bool
  default     = false
}

variable "infrastructure_ecs_cluster_autoscaling_slack_notifications" {
  description = "Send autoscaling activity to the account's CloudWatch Slack alerts SNS topic: ECS services' target tracking alarms going into ALARM (scaling out or in), ECS cluster instance launches and terminations caused by a scaling policy or scheduled action, failed instance launches and terminations, and ECS task placement failures. On a cluster with infrastructure_ecs_cluster_capacity_provider, tasks short of capacity wait in PROVISIONING rather than failing placement, so a scale-out held at the ASG's max_size is not reported. Requires the account-bootstrap CloudWatch Slack alerts (topic and KMS key alias)."
  type        = bool
  default     = false
}

variable "infrastructure_ecs_cluster_enable_debug_mode" {
  description = "Enable debug mode for ECS and Docker on the Infrastructure ECS. This should only be enabled when debugging (Can cause a lot of logs)"
  type        = bool
}

variable "infrastructure_ecs_cluster_enable_execute_command_logging" {
  description = "Enable ECS Exec logging for services within the cluster. This will log to the infrastructure logs S3 bucket"
  type        = bool
}

variable "infrastructure_ecs_cluster_syslog_endpoint" {
  description = "ECS Infrastructure Syslog endpoint. If specified, rsyslog will be installed on the ECS container instances and configured to send logs to this endpoint. Logspout containers will also be launched to gather and send Docker logs (Application logs from the running ECS services). The port must be included in the URI, eg. 'syslog+tls://example.com:1234'"
  type        = string
}

variable "infrastructure_ecs_cluster_syslog_permitted_peer" {
  description = "Specify the certificate common name (CN) of the remote to ensure syslog communication is restricted to permitted endpoints (eg. '*.example.com')"
  type        = string
}

variable "infrastructure_ecs_cluster_logspout_command" {
  description = "If provided, a logspout container will be launched on each container instance with the given command. If specified, container logs will no longer automatically be sent to CloudWatch, or to the given `infrastructure_ecs_cluster_syslog_endpoint`"
  type        = list(string)
}

variable "infrastructure_ecs_cluster_wafs" {
  description = <<EOT
    Map of WAF ACLs to create, which can be used with service CloudFront distributions
    {
      waf-name = {
        default_action: Action for requests no rule matches - 'allow' (the default) or 'block'. Set to 'block' with an allow list to restrict access to listed addresses only
        ipv4_deny_list: List of IPv4 CIDRs to block
        ipv4_allow_list: List of IPv4 CIDRs to allow, bypassing the managed and rate limiting rules
        ipv6_deny_list: List of IPv6 CIDRs to block
        ipv6_allow_list: List of IPv6 CIDRs to allow, bypassing the managed and rate limiting rules
        aws_managed_rules: List of AWS managed rule groups to apply ({ name = "AWSManagedRulesCommonRuleSet", action = "block" }). `exclude_rules` overrides named rules to count, `challenge_rules` and `captcha_rules` override them to challenge or captcha, `excluded_path_patterns` skips the group for URI paths containing any pattern, and `bot_control_inspection_level` ('COMMON' or 'TARGETED') applies to AWSManagedRulesBotControlRuleSet only
        geo_rules: List of geo match rules ({ name = "ChallengeNonUK", country_codes = ["GB"], negate = true, action = "challenge", excluded_path_regex = "^/api/auth/" }). `action` is one of block, challenge, captcha or count; `negate` matches requests NOT from the listed countries
        rate_rules: List of per-IP rate rules scoped to a URI path regex and optionally to HTTP methods ({ name = "LoginRateLimit", limit = 20, evaluation_window_sec = 300, action = "block", path_regex = "^/login$", methods = ["POST"] })
        rate_limiting: Site-wide per-IP rate limiting ({ enabled = true, limit = 1000, evaluation_window_sec = 300 })
        challenge_immunity_time_sec: Seconds a solved challenge token stays valid (WAF default is 300)
        captcha_immunity_time_sec: Seconds a solved CAPTCHA token stays valid (WAF default is 300)
        logging: Send WAF logs to a CloudWatch log group in us-east-1 ({ enabled = true, retention = 30 })
      }
    }
  EOT
  type = map(object({
    default_action  = optional(string, "allow")
    ipv4_deny_list  = optional(list(string), null)
    ipv4_allow_list = optional(list(string), null)
    ipv6_deny_list  = optional(list(string), null)
    ipv6_allow_list = optional(list(string), null)
    aws_managed_rules = optional(list(object({
      name                         = string
      action                       = string
      exclude_rules                = optional(list(string), null)
      challenge_rules              = optional(list(string), null)
      captcha_rules                = optional(list(string), null)
      excluded_path_patterns       = optional(list(string), null)
      bot_control_inspection_level = optional(string, null)
    })), null)
    geo_rules = optional(list(object({
      name                = string
      country_codes       = list(string)
      negate              = optional(bool, false)
      action              = optional(string, "challenge")
      excluded_path_regex = optional(string, null)
    })), null)
    rate_rules = optional(list(object({
      name                  = string
      limit                 = number
      evaluation_window_sec = optional(number, 300)
      action                = optional(string, "block")
      path_regex            = string
      methods               = optional(list(string), null)
    })), null)
    rate_limiting = optional(object({
      enabled               = bool
      limit                 = optional(number, 1000)
      evaluation_window_sec = optional(number, 300)
    }), null)
    challenge_immunity_time_sec = optional(number, null)
    captcha_immunity_time_sec   = optional(number, null)
    logging = optional(object({
      enabled   = bool
      retention = optional(number, 30)
    }), null)
  }))
  validation {
    condition = alltrue([
      for waf in var.infrastructure_ecs_cluster_wafs :
      waf.rate_limiting != null && waf.rate_limiting.enabled && waf.rate_limiting.evaluation_window_sec != null ?
      contains([60, 120, 300, 600], waf.rate_limiting.evaluation_window_sec) :
      true
    ])
    error_message = "Valid values for evaluation_window_sec are 60, 120, 300, and 600."
  }
  validation {
    condition = alltrue([
      for waf in var.infrastructure_ecs_cluster_wafs : contains(["allow", "block"], waf.default_action)
    ])
    error_message = "Valid values for default_action are allow and block."
  }
  validation {
    condition = alltrue(flatten([
      for waf in var.infrastructure_ecs_cluster_wafs : [
        for rule in waf.aws_managed_rules != null ? waf.aws_managed_rules : [] :
        rule.bot_control_inspection_level == null || (
          rule.name == "AWSManagedRulesBotControlRuleSet" && contains(["COMMON", "TARGETED"], coalesce(rule.bot_control_inspection_level, "COMMON"))
        )
      ]
    ]))
    error_message = "bot_control_inspection_level must be COMMON or TARGETED and is only valid on AWSManagedRulesBotControlRuleSet."
  }
  validation {
    condition = alltrue(flatten([
      for waf in var.infrastructure_ecs_cluster_wafs : [
        for rule in waf.geo_rules != null ? waf.geo_rules : [] :
        contains(["block", "challenge", "captcha", "count"], rule.action) && length(rule.country_codes) > 0
      ]
    ]))
    error_message = "geo_rules need at least one country code and an action of block, challenge, captcha or count."
  }
  validation {
    condition = alltrue(flatten([
      for waf in var.infrastructure_ecs_cluster_wafs : [
        for rule in waf.rate_rules != null ? waf.rate_rules : [] :
        contains(["block", "challenge", "captcha", "count"], rule.action) && contains([60, 120, 300, 600], rule.evaluation_window_sec)
      ]
    ]))
    error_message = "rate_rules need an action of block, challenge, captcha or count, and an evaluation_window_sec of 60, 120, 300 or 600."
  }
  validation {
    condition = alltrue(flatten([
      for waf in var.infrastructure_ecs_cluster_wafs : [
        for rule in waf.rate_rules != null ? waf.rate_rules : [] :
        rule.methods == null || (
          length(coalesce(rule.methods, [])) > 0 && alltrue([for m in coalesce(rule.methods, []) : can(regex("^[A-Z]+$", m))])
        )
      ]
    ]))
    error_message = "rate_rules methods must be omitted or a non-empty list of upper-case HTTP methods, for example [\"POST\"]. WAF matches the method exactly, so a lower-case entry would never match."
  }
  validation {
    condition = alltrue([
      for waf in var.infrastructure_ecs_cluster_wafs :
      length(waf.geo_rules != null ? waf.geo_rules : []) <= 90 &&
      length(waf.aws_managed_rules != null ? waf.aws_managed_rules : []) <= 100 &&
      length(waf.rate_rules != null ? waf.rate_rules : []) <= 800
    ])
    error_message = "Rule priorities are banded (geo 10+, managed 100+, rate 200+, RateLimit 1000), so a WAF may have at most 90 geo_rules, 100 aws_managed_rules and 800 rate_rules."
  }
  validation {
    condition = alltrue(flatten([
      for waf in var.infrastructure_ecs_cluster_wafs : [
        for rule in waf.aws_managed_rules != null ? waf.aws_managed_rules : [] :
        length(setintersection(
          toset(rule.exclude_rules != null ? rule.exclude_rules : []),
          toset(rule.challenge_rules != null ? rule.challenge_rules : []),
        )) == 0 &&
        length(setintersection(
          toset(rule.exclude_rules != null ? rule.exclude_rules : []),
          toset(rule.captcha_rules != null ? rule.captcha_rules : []),
        )) == 0 &&
        length(setintersection(
          toset(rule.challenge_rules != null ? rule.challenge_rules : []),
          toset(rule.captcha_rules != null ? rule.captcha_rules : []),
        )) == 0
      ]
    ]))
    error_message = "A managed rule may appear in only one of exclude_rules, challenge_rules and captcha_rules; WAF rejects an ACL with two overrides for the same rule."
  }
}

variable "infrastructure_ecs_cluster_service_defaults" {
  description = "Default values for ECS Cluster Services"
  type = object({
    github_v1_source           = optional(bool, null)
    github_v1_oauth_token      = optional(string, null)
    codestar_connection_arn    = optional(string, null)
    github_owner               = optional(string, null)
    github_repo                = optional(string, null)
    github_track_revision      = optional(string, null)
    buildspec                  = optional(string, null)
    buildspec_from_github_repo = optional(bool, null)
    codebuild_environment_variables = optional(list(object({
      name  = string
      value = string
    })), [])
    codebuild_compute_type        = optional(string, null)
    codebuild_image               = optional(string, null)
    ecr_scan_target_sns_topic_arn = optional(string, null)
    deployment_type               = optional(string, null)
    enable_cloudwatch_logs        = optional(bool, null)
    cloudwatch_logs_retention     = optional(number, null)
    enable_execute_command        = optional(bool, null)
    deregistration_delay          = optional(number, null)
    custom_policies = optional(map(object({
      description = string
      policy = object({
        Version = string
        Statement = list(object({
          Action   = list(string)
          Effect   = string
          Resource = list(string)
        }))
      })
    })), {})
    container_entrypoint         = optional(list(string), null)
    container_port               = optional(number, null)
    container_volumes            = optional(list(map(string)), null)
    container_extra_hosts        = optional(list(map(string)), null)
    container_count              = optional(number, null)
    container_heath_check_path   = optional(string, null)
    container_heath_grace_period = optional(number, null)
    container_memory_reservation = optional(number, null)
    container_cpu                = optional(number, null)
    autoscaling = optional(object({
      min_count                  = number
      max_count                  = number
      target_requests_per_target = number
      scale_in_cooldown          = optional(number, 300)
      scale_out_cooldown         = optional(number, 60)
    }), null)
    scheduled_tasks = optional(map(object({
      entrypoint          = optional(list(string), null)
      schedule_expression = string
    })), {})
    domain_names                                  = optional(list(string), null)
    enable_cloudfront                             = optional(bool, null)
    cloudfront_tls_certificate_arn                = optional(string, null)
    cloudfront_access_logging_enabled             = optional(bool, null)
    cloudfront_bypass_protection_enabled          = optional(bool, null)
    cloudfront_bypass_protection_excluded_domains = optional(list(string), null)
    cloudfront_origin_shield_enabled              = optional(bool, null)
    cloudfront_managed_cache_policy               = optional(string, null)
    cloudfront_managed_origin_request_policy      = optional(string, null)
    cloudfront_managed_response_headers_policy    = optional(string, null)
    cloudfront_waf_association                    = optional(string, null)
    alb_tls_certificate_arn                       = optional(string, null)
    cognito_user_pools                            = optional(list(string), [])
    cognito_user_pool_actions = optional(list(string), [
      "cognito-idp:AdminGetUser",
      "cognito-idp:AdminConfirmSignUp",
      "cognito-idp:AdminSetUserPassword",
      "cognito-idp:AdminUpdateUserAttributes",
      "cognito-idp:AdminDisableUser",
      "cognito-idp:AdminEnableUser",
      "cognito-idp:AdminDeleteUser",
      "cognito-idp:AdminUserGlobalSignOut",
      "cognito-idp:ListUsers",
    ])
    cloudfront_cache_policies = optional(map(object({
      min_ttl                    = optional(number, 0)
      default_ttl                = optional(number, 86400)
      max_ttl                    = optional(number, 31536000)
      cookies_in_cache_key       = optional(string, "none")
      query_strings_in_cache_key = optional(string, "all")
      headers_in_cache_key       = optional(list(string), [])
    })), null)
    cloudfront_cache_behaviours = optional(list(object({
      path_pattern = string
      cache_policy = string
    })), null)
    cloudfront_enhanced_metrics_enabled = optional(bool, null)
    cloudfront_custom_error_responses = optional(list(object({
      error_code            = number
      response_code         = optional(number, null)
      response_page_path    = string
      error_caching_min_ttl = optional(number, 10)
    })), null)
  })
  validation {
    condition = (
      length(var.infrastructure_ecs_cluster_service_defaults.cognito_user_pool_actions) > 0 &&
      alltrue([
        for action in var.infrastructure_ecs_cluster_service_defaults.cognito_user_pool_actions :
        can(regex("^cognito-idp:(Admin[A-Za-z]+|ListUsers|ListUsersInGroup|ListGroups)$", action))
      ])
    )
    error_message = "cognito_user_pool_actions must be Cognito Admin* user actions or ListUsers/ListUsersInGroup/ListGroups; pool-management actions and wildcards are not allowed."
  }
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
        codebuild_environment_variables: List of codebuild environment variable objects (eg. [{ name = "MY_VAR", value = "foo" },{ name = "MY_OTHER_VAR", value = "bar"}])
        codebuild_compute_type: The CodeBuild compute type for the image build (eg. BUILD_GENERAL1_MEDIUM). Defaults to BUILD_GENERAL1_SMALL
        codebuild_image: The CodeBuild image for the image build (eg. aws/codebuild/standard:7.0). Defaults to aws/codebuild/standard:5.0. Docker 23 and later, as in standard:7.0, builds with BuildKit by default
        ecr_scan_target_sns_topic_arn: An SNS topic ARN to publish ECR scan results to
        deployment_type: The service deployment type - Can be one of 'rolling' or 'blue-green'
        enable_cloudwatch_logs: Conditionally enable cloudwatch logs for the service
        cloudwatch_logs_retention: CloudWatch log retention in days
        enable_execute_command: Enable Amazon ECS Exec to directly interact with containers
        deregistration_delay: Amount time for Elastic Load Balancing to wait before changing the state of a deregistering target from draining to unused
        custom_policies: Map of custom policies to attach to the service task role (eg. { policy-name = { description = \"my custom policy\", policy = { Version = \"2012-10-17\", Statement = [] } } })
        container_entrypoint: The container entrypoint
        container_port: The service container port
        container_volumes: List of maps containing volume mappings eg. [ { "name" = "my-volume", "host_path" = "/mnt/efs/my-dir", "container_path" = "/mnt/my-dir" } ]
        container_extra_hosts: List of maps containing extra hosts eg. [ { "hostname" = "my.host", "ip_address" = "10.1.2.3" } ]
        container_count: Number of containers to launch for the service
        container_heath_check_path: Destination for the health check request
        container_heath_grace_period: Seconds to ignore failing load balancer health checks on newly instantiated tasks to prevent premature shutdown
        container_memory_reservation: Soft memory reservation for the container in MiB (default 16). Set it to what the process really uses so ECS can place tasks and scale instances correctly
        container_cpu: CPU units reserved for the container (1024 = one vCPU). Omitted when unset
        autoscaling: Scale the service's task count on ALB requests per task per minute, summed over the service's target groups, eg. { min_count = 2, max_count = 8, target_requests_per_target = 300, scale_in_cooldown = 300, scale_out_cooldown = 60 }. Requires a container_port. When unset the service runs exactly container_count tasks
        scheduled_tasks: A map of scheduled tasks that use the same image as the service defined eg. { "name" => { "entrypoint" = ["bundle", "exec", "run_jobs"], "schedule_expression" = "cron(* * * * ? *)" } }
        domain_names: Domain names to assign to CloudFront aliases, and the Application Load Balancer's `host_header` condition
        enable_cloudfront: Enable cloadfront for the service
        cloudfront_tls_certificate_arn: Certificate ARN to attach to CloudFront - must contain the names provided in `domain_names`
        cloudfront_access_logging_enabled: Enable access logging for the distribution to the infrastructure S3 logs bucket
        cloudfront_bypass_protection_enabled: This adds a secret header at the CloudFront level, which is then checked by the ALB listener rules. Requests are only forwarded if the header matches, preventing requests going directly to the ALB.
        cloudfront_bypass_protection_excluded_domains: A list of domains to exclude from the bypass protection
        cloudfront_origin_shield_enabled: Enable CloudFront Origin Shield
        cloudfront_managed_cache_policy: Conditionally specify a CloudFront Managed Cache Policy for the distribution
        cloudfront_managed_origin_request_policy: Conditionally specify a CloudFront Managed Origin Request Policy for the distribution
        cloudfront_managed_response_headers_policy: Conditionally specify a CloudFront Managed Response Headers Policy for the distribution
        cloudfront_waf_association: Conditionally associate WAF created via `infrastructure_ecs_cluster_wafs` using the key of the waf configuration
        cloudfront_cache_policies: Map of custom cache policies for the distribution's extra cache behaviours, eg. { static-assets = { default_ttl = 86400 } }. Defaults: min_ttl 0, default_ttl 86400, max_ttl 31536000, no cookies and all query strings in the cache key, no headers. default_ttl only applies when the origin sends no Cache-Control or Expires header
        cloudfront_cache_behaviours: List of extra cache behaviours in evaluation order, each a CloudFront path pattern and the key of a `cloudfront_cache_policies` entry, eg. [{ path_pattern = "*.png", cache_policy = "static-assets" }]. They share the default behaviour's origin, origin request policy and response headers policy
        cloudfront_enhanced_metrics_enabled: Subscribe the distribution to CloudFront's additional CloudWatch metrics (cache hit rate, origin latency, error rates by status code). Billed per distribution
        cloudfront_custom_error_responses: List of origin error codes to answer with a static page served from a path on the same distribution, eg. [{ error_code = 503, response_page_path = "/__errors/503.html", error_caching_min_ttl = 30 }]. response_code defaults to error_code. The page must come from an origin other than the service, typically a custom S3 bucket served through the distribution at that path
        alb_tls_certificate_arn: Certificate ARN to attach to the Application Load Balancer - must contain the names provided in `domain_names`
        cognito_user_pools: List of Cognito User Pool names (keys of `infrastructure_cognito_user_pools`) the service task role may administer
        cognito_user_pool_actions: List of `cognito-idp` IAM actions granted on those pools. Defaults to the Admin actions an application needs to own registration, password reset, account state and session revocation. Must be Cognito Admin* user actions or ListUsers/ListUsersInGroup/ListGroups; pool-management actions and wildcards are not allowed
      }
    }
  EOT
  type = map(object({
    github_v1_source           = optional(bool, null)
    github_v1_oauth_token      = optional(string, null)
    codestar_connection_arn    = optional(string, null)
    github_owner               = optional(string, null)
    github_repo                = optional(string, null)
    github_track_revision      = optional(string, null)
    buildspec                  = optional(string, null)
    buildspec_from_github_repo = optional(bool, null)
    codebuild_environment_variables = optional(list(object({
      name  = string
      value = string
    })), [])
    codebuild_compute_type        = optional(string, null)
    codebuild_image               = optional(string, null)
    ecr_scan_target_sns_topic_arn = optional(string, null)
    deployment_type               = optional(string, null)
    enable_cloudwatch_logs        = optional(bool, null)
    cloudwatch_logs_retention     = optional(number, null)
    enable_execute_command        = optional(bool, null)
    deregistration_delay          = optional(number, null)
    custom_policies = optional(map(object({
      description = string
      policy = object({
        Version = string
        Statement = list(object({
          Action   = list(string)
          Effect   = string
          Resource = list(string)
        }))
      })
    })), {})
    container_entrypoint         = optional(list(string), null)
    container_port               = optional(number, null)
    container_volumes            = optional(list(map(string)), null)
    container_extra_hosts        = optional(list(map(string)), null)
    container_count              = optional(number, null)
    container_heath_check_path   = optional(string, null)
    container_heath_grace_period = optional(number, null)
    container_memory_reservation = optional(number, null)
    container_cpu                = optional(number, null)
    autoscaling = optional(object({
      min_count                  = number
      max_count                  = number
      target_requests_per_target = number
      scale_in_cooldown          = optional(number, 300)
      scale_out_cooldown         = optional(number, 60)
    }), null)
    scheduled_tasks = optional(map(object({
      entrypoint          = list(string)
      schedule_expression = string
    })), null)
    domain_names                                  = optional(list(string), null)
    enable_cloudfront                             = optional(bool, null)
    cloudfront_tls_certificate_arn                = optional(string, null)
    cloudfront_access_logging_enabled             = optional(bool, null)
    cloudfront_bypass_protection_enabled          = optional(bool, null)
    cloudfront_bypass_protection_excluded_domains = optional(list(string), null)
    cloudfront_origin_shield_enabled              = optional(bool, null)
    cloudfront_managed_cache_policy               = optional(string, null)
    cloudfront_managed_origin_request_policy      = optional(string, null)
    cloudfront_managed_response_headers_policy    = optional(string, null)
    cloudfront_waf_association                    = optional(string, null)
    alb_tls_certificate_arn                       = optional(string, null)
    cognito_user_pools                            = optional(list(string), null)
    cognito_user_pool_actions                     = optional(list(string), null)
    cloudfront_cache_policies = optional(map(object({
      min_ttl                    = optional(number, 0)
      default_ttl                = optional(number, 86400)
      max_ttl                    = optional(number, 31536000)
      cookies_in_cache_key       = optional(string, "none")
      query_strings_in_cache_key = optional(string, "all")
      headers_in_cache_key       = optional(list(string), [])
    })), null)
    cloudfront_cache_behaviours = optional(list(object({
      path_pattern = string
      cache_policy = string
    })), null)
    cloudfront_enhanced_metrics_enabled = optional(bool, null)
    cloudfront_custom_error_responses = optional(list(object({
      error_code            = number
      response_code         = optional(number, null)
      response_page_path    = string
      error_caching_min_ttl = optional(number, 10)
    })), null)
  }))
  validation {
    condition = alltrue([
      for k, v in var.infrastructure_ecs_cluster_services :
      v["cognito_user_pool_actions"] == null || (
        length(coalesce(v["cognito_user_pool_actions"], [])) > 0 &&
        alltrue([
          for action in coalesce(v["cognito_user_pool_actions"], []) :
          can(regex("^cognito-idp:(Admin[A-Za-z]+|ListUsers|ListUsersInGroup|ListGroups)$", action))
        ])
      )
    ])
    error_message = "cognito_user_pool_actions must be Cognito Admin* user actions or ListUsers/ListUsersInGroup/ListGroups; pool-management actions and wildcards are not allowed."
  }
}

variable "infrastructure_rds_defaults" {
  description = "Default values for RDSs"
  type = object({
    type                                = optional(string, null)
    engine                              = optional(string, null)
    engine_version                      = optional(string, null)
    parameters                          = optional(map(string), null)
    instance_class                      = optional(string, null)
    allocated_storage                   = optional(number, null)
    storage_type                        = optional(string, null)
    dedicated_kms_key                   = optional(bool, null)
    dedicated_kms_key_policy_statements = optional(string, null)
    iops                                = optional(number, null)
    storage_throughput                  = optional(number, null)
    multi_az                            = optional(bool, null)
    monitoring_interval                 = optional(number, null)
    cloudwatch_logs_export_types        = optional(list(string), null)
    cluster_instance_count              = optional(number, null)
    cluster_serverlessv2_min_capacity   = optional(number, null)
    cluster_serverlessv2_max_capacity   = optional(number, null)
  })
}

variable "infrastructure_rds" {
  description = <<EOT
    Map of RDSs (The key will be the rds name). Values in here will override `infrastructure_rds_defaults` values if set."
    {
      rds-name = {
        type: Choose either `instance` for RDS instance, or `cluster` for RDS Aurora
        engine: RDS engine (Either `mysql` or `postgres`)
        engine_version: RDS Engine version. For `mysql` give major.minor (eg. `8.0`, `8.4`); for `postgres` give the major only (eg. `17`). Never give a patch version, to prevent terraform attempting to downgrade minor versions
        parameters: Map of Parameters for the DB parameter group ({ parameter-name = parameter-value, ... })
        instance_class: RDS instance class
        allocated_storage: RDS allocated storage
        storage_type: RDS storage type
        dedicated_kms_key: If enabled, will create and use a dedicated KMS key, rather than the infrastructure KMS key
        dedicated_kms_key_policy_statements: Additional KMS key policies to add to the dedicated KMS key policy
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
    type                                = optional(string, null)
    engine                              = optional(string, null)
    engine_version                      = optional(string, null)
    parameters                          = optional(map(string), null)
    instance_class                      = optional(string, null)
    allocated_storage                   = optional(number, null)
    storage_type                        = optional(string, null)
    dedicated_kms_key                   = optional(bool, null)
    dedicated_kms_key_policy_statements = optional(string, null)
    iops                                = optional(number, null)
    storage_throughput                  = optional(number, null)
    multi_az                            = optional(bool, null)
    monitoring_interval                 = optional(number, null)
    cloudwatch_logs_export_types        = optional(list(string), null)
    cluster_instance_count              = optional(number, null)
    cluster_serverlessv2_min_capacity   = optional(number, null)
    cluster_serverlessv2_max_capacity   = optional(number, null)
  }))
}

variable "enable_infrastructure_rds_backup_to_s3" {
  description = "Enable Infrastructure RDS backups to S3. This will create a scheduled Fargate task to take SQL dumps and upload them to S3"
  type        = bool
}

variable "infrastructure_rds_backup_to_s3_cron_expression" {
  description = "Cron expression for when to trigger the SQL backups to S3"
  type        = string
}

variable "infrastructure_rds_backup_to_s3_retention" {
  description = "Retention in days to keep the S3 SQL backups"
  type        = number
}

variable "infrastructure_elasticache_defaults" {
  description = "Default values for ElastiCaches"
  type = object({
    type                     = optional(string, null)
    engine                   = optional(string, null)
    engine_version           = optional(string, null)
    parameters               = optional(map(string), null)
    cluster_node_type        = optional(string, null)
    cluster_node_count       = optional(number, null)
    serverless_max_storage   = optional(number, null)
    serverless_max_ecpu      = optional(number, null)
    snapshot_retention_limit = optional(number, null)
  })
}

variable "infrastructure_elasticache" {
  description = <<EOT
    Map of Elasticaches (The key will be the elasticache name). Values in here will override `infrastructure_elasticache_defaults` values if set."
    {
      elasticache-name = {
        type: Choose either `cluster` or `serverless`
        engine: ElastiCache engine (Only `redis` is currently supported)
        engine_version: ElastiCache Engine version (For serverless, Specify the major version only)
        parameters: Map of Parameters for the ElastiCache parameter group ({ parameter-name = parameter-value, ... })
        cluster_node_type: ElastiCache Cluster node type
        cluster_node_count: ElastiCache Cluster node count
        serverless_max_storage: Serverless maximum storage
        serverless_max_ecpu: Serverless maximum number of ECPUs the cache can consume per second (1000 - 15000000)
        snapshot_retention_limit: Snapshot retention limit
      }
    }
  EOT
  type = map(object({
    type                     = optional(string, null)
    engine                   = optional(string, null)
    engine_version           = optional(string, null)
    parameters               = optional(map(string), null)
    cluster_node_type        = optional(string, null)
    cluster_node_count       = optional(number, null)
    serverless_max_storage   = optional(string, null)
    serverless_max_ecpu      = optional(number, null)
    snapshot_retention_limit = optional(number, null)
  }))
}

variable "infrastructure_cognito_user_pools_defaults" {
  description = "Default values for Cognito User Pools. `client_defaults` applies to every client of every pool unless the client sets the field itself."
  type = object({
    deletion_protection      = optional(bool, true)
    password_minimum_length  = optional(number, 16)
    password_require_symbols = optional(bool, false)
    custom_attributes = optional(map(object({
      type    = string
      mutable = optional(bool, true)
    })), {})
    threat_protection = optional(string, "OFF")
    client_defaults = optional(object({
      generate_secret               = optional(bool, true)
      explicit_auth_flows           = optional(list(string), ["ALLOW_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"])
      access_token_validity_minutes = optional(number, 60)
      id_token_validity_minutes     = optional(number, 60)
      refresh_token_validity_days   = optional(number, 1)
      enable_token_revocation       = optional(bool, true)
    }), {})
  })
  default = {}

  validation {
    condition     = var.infrastructure_cognito_user_pools_defaults.password_minimum_length >= 8 && var.infrastructure_cognito_user_pools_defaults.password_minimum_length <= 99
    error_message = "password_minimum_length must be between 8 and 99."
  }

  validation {
    condition     = length(var.infrastructure_cognito_user_pools_defaults.client_defaults.explicit_auth_flows) > 0
    error_message = "explicit_auth_flows must be a non-empty list of ALLOW_* flow names."
  }

  validation {
    condition = (
      var.infrastructure_cognito_user_pools_defaults.client_defaults.access_token_validity_minutes >= 5 &&
      var.infrastructure_cognito_user_pools_defaults.client_defaults.access_token_validity_minutes <= 1440 &&
      var.infrastructure_cognito_user_pools_defaults.client_defaults.id_token_validity_minutes >= 5 &&
      var.infrastructure_cognito_user_pools_defaults.client_defaults.id_token_validity_minutes <= 1440
    )
    error_message = "access_token_validity_minutes and id_token_validity_minutes must be between 5 and 1440 minutes."
  }

  validation {
    condition     = var.infrastructure_cognito_user_pools_defaults.client_defaults.refresh_token_validity_days >= 1 && var.infrastructure_cognito_user_pools_defaults.client_defaults.refresh_token_validity_days <= 3650
    error_message = "refresh_token_validity_days must be between 1 and 3650 days."
  }
}

variable "infrastructure_cognito_user_pools" {
  description = <<EOT
    Map of Cognito User Pools (The key will be the pool name). Values in here will override `infrastructure_cognito_user_pools_defaults` values if set.
    Pools use email as the username, verified-email account recovery, and never send email themselves: `auto_verified_attributes` is empty and no email configuration is set, so the consuming application must own registration, verification and password-reset messaging and confirm the outcome through the Cognito Admin APIs.
    `custom_attributes` is applied on create only; changing it later is silently ignored (`ignore_changes = [schema]`), so a new attribute needs a new pool under a new key.
    {
      pool-name = {
        deletion_protection: Enable deletion protection on the pool (default true)
        password_minimum_length: Minimum password length (default 16, dxw policy; validated 8-99). Upper case, lower case and numbers are always required
        password_require_symbols: Require at least one symbol (default false)
        custom_attributes: Map of custom attribute name to { type = "Boolean" | "String" | "Number", mutable = bool }. Declared without the `custom:` prefix
        threat_protection: `OFF` (default), `AUDIT` or `ENFORCED`. Anything other than `OFF` moves the pool to the Plus feature plan, which is charged per monthly active user. With no MFA and no email configuration, ENFORCED can only block risky sign-ins; it cannot notify users.
        clients: Map of app clients (The key will be the client name)
          generate_secret: Generate a client secret (default from `client_defaults`: true)
          explicit_auth_flows: Allowed auth flows (default from `client_defaults`: ["ALLOW_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"])
          access_token_validity_minutes: Access token validity in minutes (default from `client_defaults`: 60)
          id_token_validity_minutes: ID token validity in minutes (default from `client_defaults`: 60)
          refresh_token_validity_days: Refresh token validity in days (default from `client_defaults`: 1)
          enable_token_revocation: Enable token revocation (default from `client_defaults`: true)
      }
    }
  EOT
  type = map(object({
    deletion_protection      = optional(bool, null)
    password_minimum_length  = optional(number, null)
    password_require_symbols = optional(bool, null)
    custom_attributes = optional(map(object({
      type    = string
      mutable = optional(bool, true)
    })), null)
    threat_protection = optional(string, null)
    clients = optional(map(object({
      generate_secret               = optional(bool, null)
      explicit_auth_flows           = optional(list(string), null)
      access_token_validity_minutes = optional(number, null)
      id_token_validity_minutes     = optional(number, null)
      refresh_token_validity_days   = optional(number, null)
      enable_token_revocation       = optional(bool, null)
    })), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.infrastructure_cognito_user_pools : can(regex("^[a-zA-Z0-9-]+$", k))
    ])
    error_message = "Cognito User Pool names (keys in infrastructure_cognito_user_pools) can only contain alphanumeric characters and hyphens."
  }

  validation {
    condition = alltrue(flatten([
      for k, v in var.infrastructure_cognito_user_pools : [
        for ck, cv in coalesce(v["clients"], {}) : can(regex("^[a-zA-Z0-9-]+$", ck))
      ]
    ]))
    error_message = "Cognito User Pool client names (keys in clients) can only contain alphanumeric characters and hyphens."
  }

  validation {
    condition = alltrue([
      for k, v in var.infrastructure_cognito_user_pools : contains(["OFF", "AUDIT", "ENFORCED"], coalesce(v["threat_protection"], "OFF"))
    ])
    error_message = "threat_protection must be one of OFF, AUDIT or ENFORCED."
  }

  validation {
    condition = alltrue([
      for k, v in var.infrastructure_cognito_user_pools : v["password_minimum_length"] == null || (coalesce(v["password_minimum_length"], 16) >= 8 && coalesce(v["password_minimum_length"], 16) <= 99)
    ])
    error_message = "password_minimum_length must be between 8 and 99 (Cognito's range is 6-99; Dalmatian floors it at 8 and defaults to 16)."
  }

  validation {
    condition = alltrue(flatten([
      for k, v in var.infrastructure_cognito_user_pools : [
        for ck, cv in coalesce(v["clients"], {}) : (
          cv["explicit_auth_flows"] == null || length(cv["explicit_auth_flows"]) > 0
          ) && alltrue([
            for flow in coalesce(cv["explicit_auth_flows"], []) : startswith(flow, "ALLOW_")
        ])
      ]
    ]))
    error_message = "explicit_auth_flows must be a non-empty list of ALLOW_* flow names."
  }

  validation {
    condition = alltrue(flatten([
      for k, v in var.infrastructure_cognito_user_pools : [
        for ck, cv in coalesce(v["clients"], {}) : (
          cv["access_token_validity_minutes"] == null || (cv["access_token_validity_minutes"] >= 5 && cv["access_token_validity_minutes"] <= 1440)
          ) && (
          cv["id_token_validity_minutes"] == null || (cv["id_token_validity_minutes"] >= 5 && cv["id_token_validity_minutes"] <= 1440)
        )
      ]
    ]))
    error_message = "access_token_validity_minutes and id_token_validity_minutes must be between 5 and 1440 minutes."
  }

  validation {
    condition = alltrue(flatten([
      for k, v in var.infrastructure_cognito_user_pools : [
        for ck, cv in coalesce(v["clients"], {}) :
        cv["refresh_token_validity_days"] == null || (cv["refresh_token_validity_days"] >= 1 && cv["refresh_token_validity_days"] <= 3650)
      ]
    ]))
    error_message = "refresh_token_validity_days must be between 1 and 3650 days."
  }

  validation {
    # Literal fallbacks (60/60/1) mirror client_defaults above: a variable's validation
    # block cannot reference another variable at this repo's Terraform floor (>= 1.6.5),
    # so the platform defaults are duplicated here rather than read from client_defaults.
    condition = alltrue(flatten([
      for k, v in var.infrastructure_cognito_user_pools : [
        for ck, cv in coalesce(v["clients"], {}) :
        coalesce(cv["refresh_token_validity_days"], 1) * 1440 > max(coalesce(cv["access_token_validity_minutes"], 60), coalesce(cv["id_token_validity_minutes"], 60))
      ]
    ]))
    error_message = "refresh_token_validity_days must exceed both access_token_validity_minutes and id_token_validity_minutes."
  }

  validation {
    condition = alltrue(flatten([
      for k, v in var.infrastructure_cognito_user_pools : [
        for ak, av in coalesce(v["custom_attributes"], {}) : contains(["Boolean", "String", "Number"], av["type"])
      ]
    ]))
    error_message = "custom_attributes type must be Boolean, String or Number."
  }

  validation {
    condition = alltrue(flatten([
      for k, v in var.infrastructure_cognito_user_pools : [
        for ak, av in coalesce(v["custom_attributes"], {}) : can(regex("^[A-Za-z0-9_-]{1,20}$", ak))
      ]
    ]))
    error_message = "custom_attributes names must match ^[A-Za-z0-9_-]{1,20}$ (Cognito caps custom attribute names at 20 characters)."
  }
}

variable "custom_route53_hosted_zones" {
  description = <<EOT
    Map of Route53 Hosted Zone configurations to create
    {
      example.com = {
        ns_records: Map of NS records to create ({ "domain.example.com"  = { values = ["ns1.example.com", "ns2.example.com"], ttl = 300 })
        a_records: Map of A records to create ({ "domain.example.com"  = { values = ["1.2.3.4", "5.6.7.8"], ttl = 300 })
        alias_records: Map of ALIAS records to create ({ "domain.example.com"  = { value = "example.cloudfront.com", zone_id = "Z2FDTNDATAQYW2", ipv6 = true }). `ipv6` also creates an AAAA ALIAS to the same target, which must itself answer over IPv6 (eg. a CloudFront distribution or dual-stack ALB)
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
      ipv6    = optional(bool, false)
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
        custom_kms_key_policy_statements: Conditionally add a string of comma delimited user-defined bucket policy statements (eg. '{"Effect": ...},{"Effect": ...}')
        use_aes256_encryption: Conditionally enforce using AES256 encryption, rather than the infrastructure KMS key. Also overrides `create_dedicated_kms_key`
        transition_to_ia_days: Conditionally transition objects to 'Standard Infrequent Access' storage in N days
        transition_to_glacier_days: Conditionally transition objects to 'Glacier' storage in N days
        cloudfront_dedicated_distribution: Conditionally create a CloudFront distribution to serve objects from the S3 bucket.
        cloudfront_decicated_distribution_aliases: Specify custom aliases, rather than using a generated infrastriucture subdomain
        cloudfront_decicated_distribution_tls_certificate_arn: Specify a CloudFront TLS certificate to use rather than the infrastructure wildcard certificate
        cloudfront_s3_root: Sets the S3 document root when being served from CloudFront. By default this will be '/'. If `cloudfront_infrastructure_ecs_cluster_service_path` has been set, this helps by modifying the request from `/sub-directory-path` to `/` by use of a CloudFront function.
        cloudfront_basic_auth_user_list: Map of username and password's to use as basic auth ({ alex: somepassword, joe: otherpassword })
        cloudfront_infrastructure_ecs_cluster_service: Conditionally create an Origin on a CloudFront distribution that is serving the given Infrastructure ECS Cluster Service name
        cloudfront_infrastructure_ecs_cluster_service_path: If `cloudfront_infrastructure_ecs_cluster_service`, set this to the path that objects will be served from.
        cloudfront_waf_association: Conditionally associate WAF created via `infrastructure_ecs_cluster_wafs` using the key of the waf configuration
        cloudfront_origin_shield_enabled: Enable CloudFront Origin Shield, in the infrastructure's region, on the bucket's origin. Applies to the dedicated distribution and to the origin on the service distribution set by `cloudfront_infrastructure_ecs_cluster_service`
        custom_bucket_policy_statements: Conditionally add a string of comma delimited user-defined key policy statements (eg. '{"Effect": ...},{"Effect": ...}'
        enable_missing_writes_alert: Conditionally enable an alert for missing writes to the S3 bucket.
        objects: Map of object keys to content to keep in the bucket from Terraform, eg. { "503.html" = { content = "<html>...</html>" } }. content_type is inferred from the key's extension when unset; cache_control is sent as the object's Cache-Control header
      }
    }
  EOT
  type = map(object({
    create_dedicated_kms_key                              = optional(bool, null)
    custom_kms_key_policy_statements                      = optional(string, null)
    use_aes256_encryption                                 = optional(bool, null)
    transition_to_ia_days                                 = optional(number, null)
    transition_to_glacier_days                            = optional(number, null)
    cloudfront_dedicated_distribution                     = optional(bool, null)
    cloudfront_decicated_distribution_aliases             = optional(list(string), null)
    cloudfront_decicated_distribution_tls_certificate_arn = optional(string, null)
    cloudfront_s3_root                                    = optional(string, null)
    cloudfront_s3_root_file                               = optional(string, null)
    cloudfront_basic_auth_user_list                       = optional(map(string), null)
    cloudfront_infrastructure_ecs_cluster_service         = optional(string, null)
    cloudfront_infrastructure_ecs_cluster_service_path    = optional(string, null)
    cloudfront_waf_association                            = optional(string, null)
    cloudfront_origin_shield_enabled                      = optional(bool, null)
    custom_bucket_policy_statements                       = optional(string, null)
    enable_missing_writes_alert                           = optional(bool, false)
    objects = optional(map(object({
      content       = string
      content_type  = optional(string, null)
      cache_control = optional(string, null)
    })), null)
  }))
}

variable "external_s3_buckets_missing_writes_alert" {
  description = "List of bucket names (in the same account) to monitor for missing writes."
  type        = list(string)
  default     = []
}

variable "s3_missing_writes_alert_lambda_schedule_expression" {
  description = "The schedule expression for the S3 missing writes alert Lambda function."
  type        = string
  default     = "cron(0 10 * * ? *)"
}

variable "enable_cloudformatian_s3_template_store" {
  description = "Creates an S3 bucket to store custom CloudFormation templates, which can then be referenced in `custom_cloudformation_stacks`."
  type        = bool
}

variable "custom_cloudformation_stacks" {
  description = <<EOT
    Map of CloudFormation stacks to deploy
    {
      stack-name = {
        s3_template_store_key: The filename of a CloudFormation template that is stored within the S3 bucket, created by the `enable_cloudformatian_s3_template_store`
        template_body: (Optional - use of s3_template_store_key is preferred) The CloudFormation template body
        parameters: The CloudFormation template parameters ({ parameter-name = parameter-value, ... })
        ssm_parameters: CloudFormation template parameters whose values are read from AWS SSM Parameter Store ({ parameter-name = ssm-parameter-name, ... }). Use this for secrets, so that they are not stored in plaintext in tfvars. The SSM parameter must already exist, otherwise the plan will fail. SecureString parameters are decrypted automatically. Note that a stack using `ssm_parameters` has its whole parameter map marked as sensitive, so it renders as "(sensitive value)" in plan output
        on_failure: What to do on failure, either 'DO_NOTHING', 'ROLLBACK' or 'DELETE'
        capabilities: A list of capabilities. Valid values: `CAPABILITY_NAMED_IAM`, `CAPABILITY_IAM`, `CAPABILITY_AUTO_EXPAND`
      }
    }
  EOT
  type = map(object({
    s3_template_store_key = optional(string, null)
    template_body         = optional(string, null)
    parameters            = optional(map(string), null)
    ssm_parameters        = optional(map(string), {})
    on_failure            = optional(string, null)
    capabilities          = optional(list(string), null)
  }))

  validation {
    condition = alltrue([
      for k, v in var.custom_cloudformation_stacks : can(regex("^[a-zA-Z0-9-]+$", k))
    ])
    error_message = "CloudFormation stack names (keys in custom_cloudformation_stacks) can only contain alphanumeric characters and hyphens."
  }

  validation {
    condition = alltrue([
      for k, v in var.custom_cloudformation_stacks :
      length(setintersection(
        keys(coalesce(v["parameters"], {})),
        keys(v["ssm_parameters"])
      )) == 0
    ])
    error_message = "CloudFormation stack parameters cannot be set in both `parameters` and `ssm_parameters`."
  }
}

variable "custom_resource_tags" {
  description = <<EOT
    A hacky way to add custom tags to resources
    Uses a script to add tags to resources using their ARNs
    Because Terraform will remove the tags, we may need to add a delay to running the script,
    which can be specified using var.custom_resource_tags_delay
    [
      {
        arns: Comma deliminated list of ARNs to apply the tags to
        tags: Map of key/values for the tags
      }
    ]
  EOT
  type = list(object({
    arns = string,
    tags = map(string)
  }))
}

variable "custom_resource_tags_delay" {
  description = "The delay in seconds to wait before running the tag script"
  type        = number
}

variable "custom_lambda_functions" {
  description = <<EOT
    Map of Lambda functions to deploy
    {
      function-name = {
        function_zip_s3_key: The key of a Zipped Lambda function that is stored within the S3 bucket, created by the `enable_lambda_functions_s3_store`. If a file with the same name, with the `.json` extension is found, this will be used as a policy for the function (eg. `my-function.zip` will use the `my-function.json` as a policy).
        handler: The function entrypoint in the code
        runtime: The function runtime
        memory: Amount of memory in MB your Lambda Function can use at runtime.
        timeout: Amount of time your Lambda Function has to run in seconds
        environment_variables: Map of environment variables that are accessible from the function code during execution.
        custom_policies: Map of custom policies to attach to the Lambda role
        log_retention: Days to retain logs
        launch_in_infrastructure_vpc: Conditionally launch within the infrastructure VPC. This will give access to resources launched within the VPC.
      }
    }
  EOT
  type = map(object({
    function_zip_s3_key   = optional(string, null)
    handler               = optional(string, null)
    runtime               = optional(string, null)
    memory                = optional(number, null)
    timeout               = optional(number, null)
    environment_variables = optional(map(string), null)
    custom_policies = optional(map(object({
      description = string
      policy = object({
        Version = string
        Statement = list(object({
          Action   = list(string)
          Effect   = string
          Resource = list(string)
        }))
      })
    })), {})
    log_retention                = optional(number, null)
    launch_in_infrastructure_vpc = optional(bool, null)
  }))
}

variable "s3_to_azure_ssm_arn_tenant_id" {
  description = "SSM Parameter Store ARN containing the Azure Tenant ID"
  type        = string
  default     = ""
}

variable "s3_to_azure_ssm_arn_application_id" {
  description = "SSM Parameter Store ARN containing the Azure Application ID"
  type        = string
  default     = ""
}

variable "s3_to_azure_ssm_arn_client_secret" {
  description = "SSM Parameter Store ARN containing the Azure Client Secret"
  type        = string
  default     = ""
}

variable "s3_to_azure_sync_jobs" {
  description = "Map of S3 to Azure sync jobs to be scheduled as ECS tasks. Each map key feeds the EventBridge rule name and target_id, both capped at 64 characters after the resource prefix, so keep keys short. The task needs kms:Decrypt on whatever key encrypts the source bucket, otherwise Azure cannot read the pre-signed source URL and the copy fails with CannotVerifyCopySource. Set source_custom_s3_bucket to the key of a custom_s3_buckets entry with a dedicated key, or source_kms_key_arn for a bucket managed outside this project; if neither is set the infrastructure key is assumed. cpu and memory override the task definition's defaults via the schedule's task overrides, and must be a valid Fargate combination."
  type = map(object({
    cron_expression         = string
    source_bucket_uri       = string
    source_bucket_arn       = string
    destination_url         = string
    source_custom_s3_bucket = optional(string, null)
    source_kms_key_arn      = optional(string, null)
    cpu                     = optional(string, null)
    memory                  = optional(string, null)
  }))
  default = {}
}
