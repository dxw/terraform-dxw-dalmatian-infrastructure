resource "aws_ecr_repository" "infrastructure_ecs_cluster_service" {
  for_each = local.infrastructure_ecs_cluster_services

  name = "${local.resource_prefix}-${each.key}"

  encryption_configuration {
    encryption_type = local.infrastructure_kms_encryption ? "KMS" : "AES256"
    kms_key         = local.infrastructure_kms_encryption ? aws_kms_key.infrastructure[0].arn : null
  }

  image_scanning_configuration {
    scan_on_push = true
  }
}
