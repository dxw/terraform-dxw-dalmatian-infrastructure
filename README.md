# Terraform dxw Dalmatian infrastructure

[![Terraform CI](https://github.com/dxw/terraform-dxw-dalmatian-infrastructure/actions/workflows/continuous-integration-terraform.yml/badge.svg?branch=main)](https://github.com/dxw/terraform-dxw-dalmatian-infrastructure/actions/workflows/continuous-integration-terraform.yml?branch=main)
[![GitHub release](https://img.shields.io/github/release/dxw/terraform-dxw-dalmatian-infrastructure.svg)](https://github.com/dxw/terraform-dxw-dalmatian-infrastructure/releases)

This project creates and manages resources within an AWS account for infrastructures on dxw's Dalmatian hosting platform.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.24.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.26.0 |

## Resources

| Name | Type |
|------|------|
| [aws_athena_workgroup.infrastructure_vpc_flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/athena_workgroup) | resource |
| [aws_cloudwatch_log_group.infrastructure_vpc_flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_default_network_acl.infrastructure](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_network_acl) | resource |
| [aws_eip.infrastructure_nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_flow_log.infrastructure_vpc_flow_logs_cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/flow_log) | resource |
| [aws_flow_log.infrastructure_vpc_flow_logs_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/flow_log) | resource |
| [aws_glue_catalog_database.infrastructure_vpc_flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/glue_catalog_database) | resource |
| [aws_glue_catalog_table.infrastructure_vpc_flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/glue_catalog_table) | resource |
| [aws_iam_role.infrastructure_vpc_flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.infrastructure_vpc_flow_logs_allow_cloudwatch_rw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_internet_gateway.infrastructure_public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_kms_alias.infrastructure](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.infrastructure](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_nat_gateway.infrastructure](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_network_acl.infrastructure_private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl) | resource |
| [aws_network_acl.infrastructure_public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl) | resource |
| [aws_network_acl_association.infrastructure_private_subnets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_association) | resource |
| [aws_network_acl_association.infrastructure_public_subnets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_association) | resource |
| [aws_network_acl_rule.egress_allow_all_private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.egress_allow_all_public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.egress_private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.egress_public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.ingress_allow_all_private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.ingress_allow_all_public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.ingress_private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.ingress_public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_route.infrustructure_public_internet_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.private_nat_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route_table.infrastructure_private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.infrastructure_public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.infrastructure_private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.infrastructure_public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_s3_bucket.infrastructure_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_policy.infrastructure_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.infrastructure_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.infrastructure_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.infrastructure_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_subnet.infrastructure_private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.infrastructure_public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.infrastructure](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region in which to launch resources | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | The environment name to be used as part of the resource prefix | `string` | n/a | yes |
| <a name="input_infrastructure_kms_encryption"></a> [infrastructure\_kms\_encryption](#input\_infrastructure\_kms\_encryption) | Enable infrastructure KMS encryption. This will create a single KMS key to be used across all resources that support KMS encryption. | `bool` | n/a | yes |
| <a name="input_infrastructure_logging_bucket_retention"></a> [infrastructure\_logging\_bucket\_retention](#input\_infrastructure\_logging\_bucket\_retention) | Retention in days for the infrasrtucture S3 logs. This is for the default S3 logs bucket, where all AWS service logs will be delivered | `number` | n/a | yes |
| <a name="input_infrastructure_name"></a> [infrastructure\_name](#input\_infrastructure\_name) | The infrastructure name to be used as part of the resource prefix | `string` | n/a | yes |
| <a name="input_infrastructure_vpc"></a> [infrastructure\_vpc](#input\_infrastructure\_vpc) | Enable infrastructure VPC | `bool` | n/a | yes |
| <a name="input_infrastructure_vpc_assign_generated_ipv6_cidr_block"></a> [infrastructure\_vpc\_assign\_generated\_ipv6\_cidr\_block](#input\_infrastructure\_vpc\_assign\_generated\_ipv6\_cidr\_block) | Assign generated IPv6 CIDR block on infrastructure VPC | `bool` | n/a | yes |
| <a name="input_infrastructure_vpc_cidr_block"></a> [infrastructure\_vpc\_cidr\_block](#input\_infrastructure\_vpc\_cidr\_block) | Infrastructure VPC CIDR block | `string` | n/a | yes |
| <a name="input_infrastructure_vpc_enable_dns_hostnames"></a> [infrastructure\_vpc\_enable\_dns\_hostnames](#input\_infrastructure\_vpc\_enable\_dns\_hostnames) | Enable DNS hostnames on infrastructure VPC | `bool` | n/a | yes |
| <a name="input_infrastructure_vpc_enable_dns_support"></a> [infrastructure\_vpc\_enable\_dns\_support](#input\_infrastructure\_vpc\_enable\_dns\_support) | Enable DNS support on infrastructure VPC | `bool` | n/a | yes |
| <a name="input_infrastructure_vpc_enable_network_address_usage_metrics"></a> [infrastructure\_vpc\_enable\_network\_address\_usage\_metrics](#input\_infrastructure\_vpc\_enable\_network\_address\_usage\_metrics) | Enable network address usage metrics on infrastructure VPC | `bool` | n/a | yes |
| <a name="input_infrastructure_vpc_flow_logs_cloudwatch_logs"></a> [infrastructure\_vpc\_flow\_logs\_cloudwatch\_logs](#input\_infrastructure\_vpc\_flow\_logs\_cloudwatch\_logs) | Enable VPC logs on infrastructure VPC to CloudWatch Logs | `bool` | n/a | yes |
| <a name="input_infrastructure_vpc_flow_logs_retention"></a> [infrastructure\_vpc\_flow\_logs\_retention](#input\_infrastructure\_vpc\_flow\_logs\_retention) | VPC flow logs retention in days | `number` | n/a | yes |
| <a name="input_infrastructure_vpc_flow_logs_s3_key_prefix"></a> [infrastructure\_vpc\_flow\_logs\_s3\_key\_prefix](#input\_infrastructure\_vpc\_flow\_logs\_s3\_key\_prefix) | Flow Logs by default will go into the infrastructure S3 logs bucket. This is the key prefix used to isolate them from other logs | `string` | n/a | yes |
| <a name="input_infrastructure_vpc_flow_logs_s3_with_athena"></a> [infrastructure\_vpc\_flow\_logs\_s3\_with\_athena](#input\_infrastructure\_vpc\_flow\_logs\_s3\_with\_athena) | Enable VPC flow logs in infrastructure VPC to the S3 logs bucket. A compatible Glue table/database and Athena workgroup will also be created to allow querying the logs. | `bool` | n/a | yes |
| <a name="input_infrastructure_vpc_flow_logs_traffic_type"></a> [infrastructure\_vpc\_flow\_logs\_traffic\_type](#input\_infrastructure\_vpc\_flow\_logs\_traffic\_type) | Infrastructure VPC flow logs traffic type | `string` | n/a | yes |
| <a name="input_infrastructure_vpc_instance_tenancy"></a> [infrastructure\_vpc\_instance\_tenancy](#input\_infrastructure\_vpc\_instance\_tenancy) | Infrastructure VPC instance tenancy | `string` | n/a | yes |
| <a name="input_infrastructure_vpc_network_acl_egress_custom_rules_private"></a> [infrastructure\_vpc\_network\_acl\_egress\_custom\_rules\_private](#input\_infrastructure\_vpc\_network\_acl\_egress\_custom\_rules\_private) | Infrastructure vpc egress custom rules for the private subnets. These will be evaluated before any automatically added rules. | <pre>list(object({<br>    protocol        = string<br>    from_port       = number<br>    to_port         = number<br>    action          = string<br>    cidr_block      = string<br>    ipv6_cidr_block = optional(string, null)<br>    icmp_type       = optional(number, null)<br>    icmp_code       = optional(number, null)<br>  }))</pre> | n/a | yes |
| <a name="input_infrastructure_vpc_network_acl_egress_custom_rules_public"></a> [infrastructure\_vpc\_network\_acl\_egress\_custom\_rules\_public](#input\_infrastructure\_vpc\_network\_acl\_egress\_custom\_rules\_public) | Infrastructure vpc egress custom rules for the public subnets. These will be evaluated before any automatically added rules. | <pre>list(object({<br>    protocol        = string<br>    from_port       = number<br>    to_port         = number<br>    action          = string<br>    cidr_block      = string<br>    ipv6_cidr_block = optional(string, null)<br>    icmp_type       = optional(number, null)<br>    icmp_code       = optional(number, null)<br>  }))</pre> | n/a | yes |
| <a name="input_infrastructure_vpc_network_acl_egress_lockdown_private"></a> [infrastructure\_vpc\_network\_acl\_egress\_lockdown\_private](#input\_infrastructure\_vpc\_network\_acl\_egress\_lockdown\_private) | Creates a network ACL for the private subnets which blocks all egress traffic, permitting only the ports required for resources deployed by this module and custom rules. | `bool` | n/a | yes |
| <a name="input_infrastructure_vpc_network_acl_egress_lockdown_public"></a> [infrastructure\_vpc\_network\_acl\_egress\_lockdown\_public](#input\_infrastructure\_vpc\_network\_acl\_egress\_lockdown\_public) | Creates a network ACL for the public subnets which blocks all egress traffic, permitting only the ports required for resources deployed by this module and custom rules. | `bool` | n/a | yes |
| <a name="input_infrastructure_vpc_network_acl_ingress_custom_rules_private"></a> [infrastructure\_vpc\_network\_acl\_ingress\_custom\_rules\_private](#input\_infrastructure\_vpc\_network\_acl\_ingress\_custom\_rules\_private) | Infrastructure vpc ingress custom rules for the private subnets. These will be evaluated before any automatically added rules. | <pre>list(object({<br>    protocol        = string<br>    from_port       = number<br>    to_port         = number<br>    action          = string<br>    cidr_block      = string<br>    ipv6_cidr_block = optional(string, null)<br>    icmp_type       = optional(number, null)<br>    icmp_code       = optional(number, null)<br>  }))</pre> | n/a | yes |
| <a name="input_infrastructure_vpc_network_acl_ingress_custom_rules_public"></a> [infrastructure\_vpc\_network\_acl\_ingress\_custom\_rules\_public](#input\_infrastructure\_vpc\_network\_acl\_ingress\_custom\_rules\_public) | Infrastructure vpc ingress custom rules for the public subnets. These will be evaluated before any automatically added rules. | <pre>list(object({<br>    protocol        = string<br>    from_port       = number<br>    to_port         = number<br>    action          = string<br>    cidr_block      = string<br>    ipv6_cidr_block = optional(string, null)<br>    icmp_type       = optional(number, null)<br>    icmp_code       = optional(number, null)<br>  }))</pre> | n/a | yes |
| <a name="input_infrastructure_vpc_network_acl_ingress_lockdown_private"></a> [infrastructure\_vpc\_network\_acl\_ingress\_lockdown\_private](#input\_infrastructure\_vpc\_network\_acl\_ingress\_lockdown\_private) | Creates a network ACL for the private subnets which blocks all ingress traffic, permitting only the ports required for resources deployed by this module and custom rules. | `bool` | n/a | yes |
| <a name="input_infrastructure_vpc_network_acl_ingress_lockdown_public"></a> [infrastructure\_vpc\_network\_acl\_ingress\_lockdown\_public](#input\_infrastructure\_vpc\_network\_acl\_ingress\_lockdown\_public) | Creates a network ACL for the public subnets which blocks all ingress traffic, permitting only the ports required for resources deployed by this module and custom rules. | `bool` | n/a | yes |
| <a name="input_infrastructure_vpc_network_availability_zones"></a> [infrastructure\_vpc\_network\_availability\_zones](#input\_infrastructure\_vpc\_network\_availability\_zones) | A list of availability zone characters (eg. ["a", "b", "c"]) | `list(string)` | n/a | yes |
| <a name="input_infrastructure_vpc_network_enable_private"></a> [infrastructure\_vpc\_network\_enable\_private](#input\_infrastructure\_vpc\_network\_enable\_private) | Enable private networking on Infrastructure VPC. This will create subnets with a route to a NAT Gateway (If Public networking has been enabled) | `bool` | n/a | yes |
| <a name="input_infrastructure_vpc_network_enable_public"></a> [infrastructure\_vpc\_network\_enable\_public](#input\_infrastructure\_vpc\_network\_enable\_public) | Enable public networking on Infrastructure VPC. This will create subnets with a route to an Internet Gateway | `bool` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name to be used as a prefix for all resources | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
