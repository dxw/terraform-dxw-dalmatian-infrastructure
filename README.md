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

No providers.

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region in which to launch resources | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | The environment name to be used as part of the resource prefix | `string` | n/a | yes |
| <a name="input_infrastructure_name"></a> [infrastructure\_name](#input\_infrastructure\_name) | The infrastructure name to be used as part of the resource prefix | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name to be used as a prefix for all resources | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
