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

  default_tags = {
    Project        = local.project_name,
    Infrastructure = local.infrastructure_name,
    Environment    = local.environment,
    Prefix         = local.resource_prefix,
  }
}
