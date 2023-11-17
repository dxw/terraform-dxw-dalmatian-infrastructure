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
| [aws_kms_alias.infrastructure](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.infrastructure](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_s3_bucket.infrastructure_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_policy.infrastructure_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.infrastructure_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.infrastructure_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.infrastructure_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region in which to launch resources | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | The environment name to be used as part of the resource prefix | `string` | n/a | yes |
| <a name="input_infrastructure_kms_encryption"></a> [infrastructure\_kms\_encryption](#input\_infrastructure\_kms\_encryption) | Enable infrastructure KMS encryption. This will create a single KMS key to be used across all resources that support KMS encryption. | `bool` | n/a | yes |
| <a name="input_infrastructure_logging_bucket_retention"></a> [infrastructure\_logging\_bucket\_retention](#input\_infrastructure\_logging\_bucket\_retention) | Retention in days for the infrasrtucture S3 logs. This is for the default S3 logs bucket, where all AWS service logs will be delivered | `number` | n/a | yes |
| <a name="input_infrastructure_name"></a> [infrastructure\_name](#input\_infrastructure\_name) | The infrastructure name to be used as part of the resource prefix | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name to be used as a prefix for all resources | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
