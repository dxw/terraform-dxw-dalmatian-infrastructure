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
