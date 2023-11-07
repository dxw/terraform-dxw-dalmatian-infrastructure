locals {
  project_name        = var.project_name
  infrastructure_name = var.infrastructure_name
  environment         = var.environment
  aws_region          = var.aws_region
  resource_prefix     = "${var.project_name}-${var.infrastructure_name}-${var.environment}"

  default_tags = {
    Project        = local.project_name,
    Infrastructure = local.infrastructure_name,
    Environment    = local.environment,
    Prefix         = local.resource_prefix,
  }
}
