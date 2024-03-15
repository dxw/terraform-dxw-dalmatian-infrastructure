resource "aws_s3_bucket" "infrastructure_ecs_cluster_service_build_pipeline_buildspec_store" {
  count = length(local.infrastructure_ecs_cluster_services) != 0 ? 1 : 0

  bucket = "${local.resource_prefix_hash}-ecs-cluster-service-build-pipeline-buildspec-store"

}

resource "aws_s3_bucket_policy" "infrastructure_ecs_cluster_service_build_pipeline_buildspec_store" {
  count = length(local.infrastructure_ecs_cluster_services) != 0 ? 1 : 0

  bucket = aws_s3_bucket.infrastructure_ecs_cluster_service_build_pipeline_buildspec_store[0].id
  policy = templatefile(
    "${path.module}/policies/s3-bucket-policy.json.tpl",
    {
      statement = <<EOT
      [
      ${templatefile("${path.root}/policies/s3-bucket-policy-statements/enforce-tls.json.tpl",
      {
        bucket_arn = aws_s3_bucket.infrastructure_ecs_cluster_service_build_pipeline_buildspec_store[0].arn
      }
  )}
      ]
      EOT
}
)
}

resource "aws_s3_bucket_public_access_block" "infrastructure_ecs_cluster_service_build_pipeline_buildspec_store" {
  count = length(local.infrastructure_ecs_cluster_services) != 0 ? 1 : 0

  bucket                  = aws_s3_bucket.infrastructure_ecs_cluster_service_build_pipeline_buildspec_store[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "infrastructure_ecs_cluster_service_build_pipeline_buildspec_store" {
  count = length(local.infrastructure_ecs_cluster_services) != 0 ? 1 : 0

  bucket = aws_s3_bucket.infrastructure_ecs_cluster_service_build_pipeline_buildspec_store[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "infrastructure_ecs_cluster_service_build_pipeline_buildspec_store" {
  count = length(local.infrastructure_ecs_cluster_services) != 0 ? 1 : 0

  bucket = aws_s3_bucket.infrastructure_ecs_cluster_service_build_pipeline_buildspec_store[0].id

  target_bucket = aws_s3_bucket.infrastructure_logs[0].id
  target_prefix = "s3/infrastructure-ecs-cluster-service-build-pipeline-buildspec-store"
}

# because infrastructure_kms_encryption is only true when multiple other
# vars are true, tfsec can't figure out that this will actually have kms encryption when
# enabled
#tfsec:ignore:aws-s3-encryption-customer-key tfsec:ignore:aws-s3-enable-bucket-encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "infrastructure_ecs_cluster_service_build_pipeline_buildspec_store" {
  count = length(local.infrastructure_ecs_cluster_services) != 0 ? 1 : 0

  bucket = aws_s3_bucket.infrastructure_ecs_cluster_service_build_pipeline_buildspec_store[0].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = local.infrastructure_kms_encryption ? aws_kms_key.infrastructure[0].arn : null
      sse_algorithm     = local.infrastructure_kms_encryption ? "aws:kms" : "AES256"
    }
  }
}

resource "aws_s3_object" "infrastructure_ecs_cluster_service_build_pipeline_buildspec_store_files" {
  for_each = length(local.infrastructure_ecs_cluster_services) != 0 ? fileset("${path.root}/buildspecs/", "*") : []

  bucket       = aws_s3_bucket.infrastructure_ecs_cluster_service_build_pipeline_buildspec_store[0].id
  key          = each.value
  source       = "${path.root}/buildspecs/${each.value}"
  source_hash  = filemd5("${path.root}/buildspecs/${each.value}")
  content_type = "text/plain"
  kms_key_id   = local.infrastructure_kms_encryption ? aws_kms_key.infrastructure[0].arn : null
}

# This user/group is most likely to be used in automation, so MFA wont be ideal
# tfsec:ignore:aws-iam-enforce-group-mfa
resource "aws_iam_group" "infrastructure_ecs_cluster_service_build_pipeline_buildspec_store" {
  count = length(local.infrastructure_ecs_cluster_services) != 0 ? 1 : 0

  name = "${local.resource_prefix_hash}-ecs-cluster-service-build-pipeline-buildspec-store"
  path = "/${local.resource_prefix}/"
}

resource "aws_iam_user" "infrastructure_ecs_cluster_service_build_pipeline_buildspec_store" {
  count = length(local.infrastructure_ecs_cluster_services) != 0 ? 1 : 0

  name = "${local.resource_prefix_hash}-ecs-cluster-service-build-pipeline-buildspec-store"
}

resource "aws_iam_group_membership" "infrastructure_ecs_cluster_service_build_pipeline_buildspec_store" {
  count = length(local.infrastructure_ecs_cluster_services) != 0 ? 1 : 0

  name = "${local.resource_prefix_hash}-ecs-cluster-service-build-pipeline-buildspec-store"

  users = [
    aws_iam_user.infrastructure_ecs_cluster_service_build_pipeline_buildspec_store[0].name,
  ]

  group = aws_iam_group.infrastructure_ecs_cluster_service_build_pipeline_buildspec_store[0].name
}


resource "aws_iam_access_key" "infrastructure_ecs_cluster_service_build_pipeline_buildspec_store" {
  count = length(local.infrastructure_ecs_cluster_services) != 0 ? 1 : 0

  user = aws_iam_user.infrastructure_ecs_cluster_service_build_pipeline_buildspec_store[0].name
}

resource "aws_iam_group_policy" "infrastructure_ecs_cluster_service_build_pipeline_buildspec_store" {
  count = length(local.infrastructure_ecs_cluster_services) != 0 ? 1 : 0

  name  = "${local.resource_prefix_hash}-ecs-cluster-service-build-pipeline-buildspec-store-rw"
  group = aws_iam_group.infrastructure_ecs_cluster_service_build_pipeline_buildspec_store[0].name
  policy = templatefile(
    "${path.root}/policies/s3-object-rw.json.tpl",
    { bucket_arn = aws_s3_bucket.infrastructure_ecs_cluster_service_build_pipeline_buildspec_store[0].arn }
  )
}
