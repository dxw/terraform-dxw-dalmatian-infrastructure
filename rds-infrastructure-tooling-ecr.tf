resource "aws_ecr_repository" "infrastructure_rds_tooling" {
  count = local.enable_infrastructure_rds_tooling ? 1 : 0

  name = "${local.resource_prefix}-rds-tooling"

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

resource "aws_ecr_lifecycle_policy" "infrastructure_rds_tooling" {
  count = local.enable_infrastructure_rds_tooling ? 1 : 0

  repository = aws_ecr_repository.infrastructure_rds_tooling[0].name
  policy = templatefile(
    "${path.module}/policies/ecr-policies/max-images.json.tpl",
    {
      max_images = 5
    }
  )
}
