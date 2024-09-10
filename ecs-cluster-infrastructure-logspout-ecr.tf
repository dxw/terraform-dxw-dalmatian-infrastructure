resource "aws_ecr_repository" "infrastructure_ecs_cluster_logspout" {
  count = local.infrastructure_ecs_cluster_logspout_enabled ? 1 : 0

  name = "${local.resource_prefix}-ecs-cluster-logspout"

  #tfsec:ignore:aws-ecr-enforce-immutable-repository
  image_tag_mutability = "MUTABLE"

  encryption_configuration {
    encryption_type = local.infrastructure_kms_encryption ? "KMS" : "AES256"
    kms_key         = local.infrastructure_kms_encryption ? aws_kms_key.infrastructure[0].arn : null
  }

  image_scanning_configuration {
    scan_on_push = true
  }
}
