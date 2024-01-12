# Terraform dxw Dalmatian infrastructure

[![Terraform CI](https://github.com/dxw/terraform-dxw-dalmatian-infrastructure/actions/workflows/continuous-integration-terraform.yml/badge.svg?branch=main)](https://github.com/dxw/terraform-dxw-dalmatian-infrastructure/actions/workflows/continuous-integration-terraform.yml?branch=main)
[![GitHub release](https://img.shields.io/github/release/dxw/terraform-dxw-dalmatian-infrastructure.svg)](https://github.com/dxw/terraform-dxw-dalmatian-infrastructure/releases)

This project creates and manages resources within an AWS account for infrastructures on dxw's Dalmatian hosting platform.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.5 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | >= 2.4.1 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.30.0 |
| <a name="requirement_external"></a> [external](#requirement\_external) | >= 2.3.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | 2.4.1 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.31.0 |
| <a name="provider_aws.awsroute53root"></a> [aws.awsroute53root](#provider\_aws.awsroute53root) | 5.31.0 |
| <a name="provider_external"></a> [external](#provider\_external) | 2.3.2 |

## Resources

| Name | Type |
|------|------|
| [aws_athena_workgroup.infrastructure_vpc_flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/athena_workgroup) | resource |
| [aws_autoscaling_group.infrastructure_ecs_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_autoscaling_lifecycle_hook.infrastructure_ecs_cluster_termination](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_lifecycle_hook) | resource |
| [aws_autoscaling_schedule.ecs_infrastructure_time_based_custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_schedule) | resource |
| [aws_autoscaling_schedule.ecs_infrastructure_time_based_max](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_schedule) | resource |
| [aws_autoscaling_schedule.ecs_infrastructure_time_based_min](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_schedule) | resource |
| [aws_cloudwatch_log_group.ecs_cluster_infrastructure_draining_lambda_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.infrastructure_vpc_flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_codebuild_project.infrastructure_ecs_cluster_service_build](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project) | resource |
| [aws_codepipeline.infrastructure_ecs_cluster_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codepipeline) | resource |
| [aws_default_network_acl.infrastructure](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_network_acl) | resource |
| [aws_ecs_cluster.infrastructure](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_efs_file_system.infrastructure_ecs_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_file_system) | resource |
| [aws_efs_mount_target.infrastructure_ecs_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_mount_target) | resource |
| [aws_eip.infrastructure_nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_flow_log.infrastructure_vpc_flow_logs_cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/flow_log) | resource |
| [aws_flow_log.infrastructure_vpc_flow_logs_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/flow_log) | resource |
| [aws_glue_catalog_database.infrastructure_vpc_flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/glue_catalog_database) | resource |
| [aws_glue_catalog_table.infrastructure_vpc_flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/glue_catalog_table) | resource |
| [aws_iam_access_key.infrastructure_ecs_cluster_service_build_pipeline_buildspec_store](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_access_key) | resource |
| [aws_iam_group.infrastructure_ecs_cluster_service_build_pipeline_buildspec_store](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_group) | resource |
| [aws_iam_group_membership.infrastructure_ecs_cluster_service_build_pipeline_buildspec_store](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_group_membership) | resource |
| [aws_iam_group_policy.infrastructure_ecs_cluster_service_build_pipeline_buildspec_store](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_group_policy) | resource |
| [aws_iam_instance_profile.infrastructure_ecs_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_policy.ecs_cluster_infrastructure_draining_ecs_container_instance_state_update_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.ecs_cluster_infrastructure_draining_kms_encrypt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.ecs_cluster_infrastructure_draining_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.ecs_cluster_infrastructure_draining_sns_publish_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.infrastructure_ecs_cluster_autoscaling_lifecycle_termination_kms_encrypt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.infrastructure_ecs_cluster_autoscaling_lifecycle_termination_sns_publish](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.infrastructure_ecs_cluster_ec2_ecs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.infrastructure_ecs_cluster_pass_role_ssm_dhmc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.infrastructure_ecs_cluster_service_codebuild](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.infrastructure_ecs_cluster_service_codebuild_kms_decrypt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.infrastructure_ecs_cluster_service_codepipeline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.infrastructure_ecs_cluster_service_codepipeline_codestar_connection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.infrastructure_ecs_cluster_service_codepipeline_kms_encrypt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.infrastructure_ecs_cluster_ssm_service_setting_rw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.ecs_cluster_infrastructure_draining_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.infrastructure_ecs_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.infrastructure_ecs_cluster_autoscaling_lifecycle_termination](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.infrastructure_ecs_cluster_service_codebuild](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.infrastructure_ecs_cluster_service_codepipeline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.infrastructure_vpc_flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.infrastructure_vpc_flow_logs_allow_cloudwatch_rw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.ecs_cluster_infrastructure_draining_ecs_container_instance_state_update_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ecs_cluster_infrastructure_draining_kms_encrypt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ecs_cluster_infrastructure_draining_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ecs_cluster_infrastructure_draining_sns_publish_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.infrastructure_ecs_cluster_autoscaling_lifecycle_termination_kms_encrypt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.infrastructure_ecs_cluster_autoscaling_lifecycle_termination_sns_publish](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.infrastructure_ecs_cluster_ec2_ecs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.infrastructure_ecs_cluster_pass_role_ssm_dhmc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.infrastructure_ecs_cluster_service_codebuild](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.infrastructure_ecs_cluster_service_codebuild_kms_decrypt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.infrastructure_ecs_cluster_service_codepipeline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.infrastructure_ecs_cluster_service_codepipeline_codestar_connection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.infrastructure_ecs_cluster_service_codepipeline_kms_encrypt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.infrastructure_ecs_cluster_ssm_service_setting_rw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_user.infrastructure_ecs_cluster_service_build_pipeline_buildspec_store](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user) | resource |
| [aws_internet_gateway.infrastructure_public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_kms_alias.infrastructure](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.infrastructure](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_lambda_function.ecs_cluster_infrastructure_draining](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.ecs_cluster_infrastructure_draining_allow_sns_execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_launch_template.infrastructure_ecs_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
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
| [aws_placement_group.infrastructure_ecs_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/placement_group) | resource |
| [aws_route.infrustructure_public_internet_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.private_nat_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route53_record.infrastructure_ns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_zone.infrastructure](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |
| [aws_route_table.infrastructure_private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.infrastructure_public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.infrastructure_private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.infrastructure_public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_s3_bucket.infrastructure_ecs_cluster_service_build_pipeline_artifact_store](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.infrastructure_ecs_cluster_service_build_pipeline_buildspec_store](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.infrastructure_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.infrastructure_ecs_cluster_service_build_pipeline_artifact_store](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_lifecycle_configuration.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_logging.infrastructure_ecs_cluster_service_build_pipeline_artifact_store](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_logging.infrastructure_ecs_cluster_service_build_pipeline_buildspec_store](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_policy.infrastructure_ecs_cluster_service_build_pipeline_artifact_store](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_policy.infrastructure_ecs_cluster_service_build_pipeline_buildspec_store](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_policy.infrastructure_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.infrastructure_ecs_cluster_service_build_pipeline_artifact_store](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_public_access_block.infrastructure_ecs_cluster_service_build_pipeline_buildspec_store](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_public_access_block.infrastructure_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.infrastructure_ecs_cluster_service_build_pipeline_artifact_store](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.infrastructure_ecs_cluster_service_build_pipeline_buildspec_store](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.infrastructure_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.infrastructure_ecs_cluster_service_build_pipeline_artifact_store](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_bucket_versioning.infrastructure_ecs_cluster_service_build_pipeline_buildspec_store](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_bucket_versioning.infrastructure_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_object.infrastructure_ecs_cluster_service_build_pipeline_buildspec_store_files](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_security_group.infrastructure_ecs_cluster_container_instances](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.infrastructure_ecs_cluster_efs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.infrastructure_ecs_cluster_container_instances_egress_dns_tcp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.infrastructure_ecs_cluster_container_instances_egress_dns_udp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.infrastructure_ecs_cluster_container_instances_egress_https_tcp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.infrastructure_ecs_cluster_container_instances_egress_https_udp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.infrastructure_ecs_cluster_container_instances_egress_nfs_tcp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.infrastructure_ecs_cluster_container_instances_ingress_tcp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.infrastructure_ecs_cluster_container_instances_ingress_udp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.infrastructure_ecs_cluster_efs_ingress_nfs_tcp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_sns_topic.infrastructure_ecs_cluster_autoscaling_lifecycle_termination](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_subscription.ecs_cluster_infrastructure_draining_autoscaling_lifecycle_termination](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_subnet.infrastructure_private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.infrastructure_public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.infrastructure](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [archive_file.ecs_cluster_infrastructure_draining_lambda](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_ami.ecs_cluster_ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_route53_zone.root](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [aws_s3_object.ecs_cluster_service_buildspec](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_object) | data source |
| [external_external.ssm_dhmc_setting](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_profile_name_route53_root"></a> [aws\_profile\_name\_route53\_root](#input\_aws\_profile\_name\_route53\_root) | AWS Profile name which is configured for the account in which the root Route53 Hosted Zone exists. | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region in which to launch resources | `string` | n/a | yes |
| <a name="input_ecs_cluster_efs_directories"></a> [ecs\_cluster\_efs\_directories](#input\_ecs\_cluster\_efs\_directories) | ECS cluster EFS directories to create | `list(string)` | n/a | yes |
| <a name="input_ecs_cluster_efs_infrequent_access_transition"></a> [ecs\_cluster\_efs\_infrequent\_access\_transition](#input\_ecs\_cluster\_efs\_infrequent\_access\_transition) | ECS cluser EFS IA transiton in days. Set to 0 to disable IA transition. | `number` | n/a | yes |
| <a name="input_ecs_cluster_efs_performance_mode"></a> [ecs\_cluster\_efs\_performance\_mode](#input\_ecs\_cluster\_efs\_performance\_mode) | ECS cluser EFS performance mode | `string` | n/a | yes |
| <a name="input_ecs_cluster_efs_throughput_mode"></a> [ecs\_cluster\_efs\_throughput\_mode](#input\_ecs\_cluster\_efs\_throughput\_mode) | ECS cluser EFS throughput mode | `string` | n/a | yes |
| <a name="input_enable_infrastructure_ecs_cluster"></a> [enable\_infrastructure\_ecs\_cluster](#input\_enable\_infrastructure\_ecs\_cluster) | Enable creation of infrastructure ECS cluster, to place ECS services | `bool` | n/a | yes |
| <a name="input_enable_infrastructure_ecs_cluster_efs"></a> [enable\_infrastructure\_ecs\_cluster\_efs](#input\_enable\_infrastructure\_ecs\_cluster\_efs) | Conditionally create and mount EFS to the ECS cluster instances | `bool` | n/a | yes |
| <a name="input_enable_infrastructure_route53_hosted_zone"></a> [enable\_infrastructure\_route53\_hosted\_zone](#input\_enable\_infrastructure\_route53\_hosted\_zone) | Creates a Route53 hosted zone, where DNS records will be created for resources launched within this module. | `bool` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | The environment name to be used as part of the resource prefix | `string` | n/a | yes |
| <a name="input_infrastructure_dockerhub_email"></a> [infrastructure\_dockerhub\_email](#input\_infrastructure\_dockerhub\_email) | Dockerhub email | `string` | n/a | yes |
| <a name="input_infrastructure_dockerhub_token"></a> [infrastructure\_dockerhub\_token](#input\_infrastructure\_dockerhub\_token) | Dockerhub token which has permissions to pull images | `string` | n/a | yes |
| <a name="input_infrastructure_ecs_cluster_ami_version"></a> [infrastructure\_ecs\_cluster\_ami\_version](#input\_infrastructure\_ecs\_cluster\_ami\_version) | AMI version for ECS cluster instances (amzn2-ami-ecs-hvm-<version>) | `string` | n/a | yes |
| <a name="input_infrastructure_ecs_cluster_autoscaling_time_based_custom"></a> [infrastructure\_ecs\_cluster\_autoscaling\_time\_based\_custom](#input\_infrastructure\_ecs\_cluster\_autoscaling\_time\_based\_custom) | List of objects with min/max sizes and cron expressions to scale the ECS cluster. Min size will be used as desired. | <pre>list(<br>    object({<br>      cron = string<br>      min  = number<br>      max  = number<br>    })<br>  )</pre> | n/a | yes |
| <a name="input_infrastructure_ecs_cluster_autoscaling_time_based_max"></a> [infrastructure\_ecs\_cluster\_autoscaling\_time\_based\_max](#input\_infrastructure\_ecs\_cluster\_autoscaling\_time\_based\_max) | List of cron expressions to scale the ECS cluster to the configured max size | `list(string)` | n/a | yes |
| <a name="input_infrastructure_ecs_cluster_autoscaling_time_based_min"></a> [infrastructure\_ecs\_cluster\_autoscaling\_time\_based\_min](#input\_infrastructure\_ecs\_cluster\_autoscaling\_time\_based\_min) | List of cron expressions to scale the ECS cluster to the configured min size | `list(string)` | n/a | yes |
| <a name="input_infrastructure_ecs_cluster_draining_lambda_enabled"></a> [infrastructure\_ecs\_cluster\_draining\_lambda\_enabled](#input\_infrastructure\_ecs\_cluster\_draining\_lambda\_enabled) | Enable the Lambda which ensures all containers have drained before terminating ECS cluster instances | `bool` | n/a | yes |
| <a name="input_infrastructure_ecs_cluster_draining_lambda_log_retention"></a> [infrastructure\_ecs\_cluster\_draining\_lambda\_log\_retention](#input\_infrastructure\_ecs\_cluster\_draining\_lambda\_log\_retention) | Log retention for the ECS cluster draining Lambda | `number` | n/a | yes |
| <a name="input_infrastructure_ecs_cluster_ebs_docker_storage_volume_size"></a> [infrastructure\_ecs\_cluster\_ebs\_docker\_storage\_volume\_size](#input\_infrastructure\_ecs\_cluster\_ebs\_docker\_storage\_volume\_size) | Size of EBS volume for Docker storage on the infrastructure ECS instances | `number` | n/a | yes |
| <a name="input_infrastructure_ecs_cluster_ebs_docker_storage_volume_type"></a> [infrastructure\_ecs\_cluster\_ebs\_docker\_storage\_volume\_type](#input\_infrastructure\_ecs\_cluster\_ebs\_docker\_storage\_volume\_type) | Type of EBS volume for Docker storage on the infrastructure ECS instances (eg. gp3) | `string` | n/a | yes |
| <a name="input_infrastructure_ecs_cluster_instance_type"></a> [infrastructure\_ecs\_cluster\_instance\_type](#input\_infrastructure\_ecs\_cluster\_instance\_type) | The instance type for EC2 instances launched in the ECS cluster | `string` | n/a | yes |
| <a name="input_infrastructure_ecs_cluster_max_instance_lifetime"></a> [infrastructure\_ecs\_cluster\_max\_instance\_lifetime](#input\_infrastructure\_ecs\_cluster\_max\_instance\_lifetime) | Maximum lifetime in seconds of an instance within the ECS cluster | `number` | n/a | yes |
| <a name="input_infrastructure_ecs_cluster_max_size"></a> [infrastructure\_ecs\_cluster\_max\_size](#input\_infrastructure\_ecs\_cluster\_max\_size) | Maximum number of instances for the ECS cluster | `number` | n/a | yes |
| <a name="input_infrastructure_ecs_cluster_min_size"></a> [infrastructure\_ecs\_cluster\_min\_size](#input\_infrastructure\_ecs\_cluster\_min\_size) | Minimum number of instances for the ECS cluster | `number` | n/a | yes |
| <a name="input_infrastructure_ecs_cluster_publicly_avaialble"></a> [infrastructure\_ecs\_cluster\_publicly\_avaialble](#input\_infrastructure\_ecs\_cluster\_publicly\_avaialble) | Conditionally launch the ECS cluster EC2 instances into the Public subnet | `bool` | n/a | yes |
| <a name="input_infrastructure_ecs_cluster_service_defaults"></a> [infrastructure\_ecs\_cluster\_service\_defaults](#input\_infrastructure\_ecs\_cluster\_service\_defaults) | Default values for ECS Cluster Services | <pre>object({<br>    github_v1_source           = optional(bool, null)<br>    github_v1_oauth_token      = optional(string, null)<br>    codestar_connection_arn    = optional(string, null)<br>    github_owner               = optional(string, null)<br>    github_repo                = optional(string, null)<br>    github_track_revision      = optional(string, null)<br>    buildspec                  = optional(string, null)<br>    buildspec_from_github_repo = optional(bool, null)<br>  })</pre> | n/a | yes |
| <a name="input_infrastructure_ecs_cluster_services"></a> [infrastructure\_ecs\_cluster\_services](#input\_infrastructure\_ecs\_cluster\_services) | Map of ECS Cluster Services (The key will be the service name). Values in here will override `infrastructure_ecs_cluster_service_defaults` values if set."<br>    {<br>      service-name = {<br>        github\_v1\_source: Conditionally use GitHubV1 for the CodePipeline source (CodeStar will be used by default)<br>        github\_v1\_oauth\_token: If `github_v1_source` is set to true, provide the GitHub OAuthToken here<br>        codestar\_connection\_arn: The CodeStar Connection ARN to use in the CodePipeline source<br>        github\_owner: The GitHub Owner of the repository to be pulled by the CodePipeline source<br>        github\_repo: The GitHub repo name to be pulled by the CodePipeline source<br>        github\_track\_revision: The branch/revision of the GitHub repository to be pulled by the CodePipeline source<br>        buildspec: The filename of the buildspec to use for the CodePipeline build phase, stored within the 'codepipeline buildspec store' S3 bucket<br>        buildspec\_from\_github\_repo: Conditionally use the 'buildspec' filename stored within the GitHub repo as the buildspec<br>      }<br>    } | <pre>map(object({<br>    github_v1_source           = optional(bool, null)<br>    github_v1_oauth_token      = optional(string, null)<br>    codestar_connection_arn    = optional(string, null)<br>    github_owner               = optional(string, null)<br>    github_repo                = optional(string, null)<br>    github_track_revision      = optional(string, null)<br>    buildspec                  = optional(string, null)<br>    buildspec_from_github_repo = optional(bool, null)<br>  }))</pre> | n/a | yes |
| <a name="input_infrastructure_ecs_cluster_termination_timeout"></a> [infrastructure\_ecs\_cluster\_termination\_timeout](#input\_infrastructure\_ecs\_cluster\_termination\_timeout) | The timeout for the terminiation lifecycle hook | `number` | n/a | yes |
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
| <a name="input_route53_root_hosted_zone_domain_name"></a> [route53\_root\_hosted\_zone\_domain\_name](#input\_route53\_root\_hosted\_zone\_domain\_name) | Route53 Hosted Zone in which to delegate Infrastructure Route53 Hosted Zones. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_resource_map"></a> [resource\_map](#output\_resource\_map) | Simplified map of resources and their dependencies, associations and attachments |
<!-- END_TF_DOCS -->
