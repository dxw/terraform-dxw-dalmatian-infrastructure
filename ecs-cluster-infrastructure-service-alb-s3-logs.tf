# https://github.com/aquasecurity/tfsec/issues/2081
# tfsec:ignore:aws-s3-enable-bucket-logging
resource "aws_s3_bucket" "infrastructure_ecs_cluster_service_alb_logs" {
  count = local.enable_infrastructure_ecs_cluster_services_alb_logs ? 1 : 0

  bucket = "${local.resource_prefix_hash}-infrastructure-ecs-cluster-service-alb-logs"
}

resource "aws_s3_bucket_policy" "infrastructure_ecs_cluster_service_alb_logs" {
  count = local.enable_infrastructure_ecs_cluster_services_alb_logs ? 1 : 0

  bucket = aws_s3_bucket.infrastructure_ecs_cluster_service_alb_logs[0].id
  policy = templatefile(
    "${path.module}/policies/s3-bucket-policy.json.tpl",
    {
      statement = <<EOT
      [
      ${templatefile("${path.root}/policies/s3-bucket-policy-statements/enforce-tls.json.tpl", { bucket_arn = aws_s3_bucket.infrastructure_ecs_cluster_service_alb_logs[0].arn })},
      ${templatefile("${path.root}/policies/s3-bucket-policy-statements/alb-logs.json.tpl", {
      bucket_arn     = aws_s3_bucket.infrastructure_ecs_cluster_service_alb_logs[0].arn,
      elb_account_id = data.aws_elb_service_account.current.id,
      account_id     = local.aws_account_id
})}
      ]
      EOT
}
)
}

resource "aws_s3_bucket_public_access_block" "infrastructure_ecs_cluster_service_alb_logs" {
  count = local.enable_infrastructure_ecs_cluster_services_alb_logs ? 1 : 0

  bucket                  = aws_s3_bucket.infrastructure_ecs_cluster_service_alb_logs[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "infrastructure_ecs_cluster_service_alb_logs" {
  count = local.enable_infrastructure_ecs_cluster_services_alb_logs ? 1 : 0

  bucket = aws_s3_bucket.infrastructure_ecs_cluster_service_alb_logs[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# The ALB logs service can only put logs to an S3 bucket with Amazon S3-managed keys (SSE-S3)
#tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket_server_side_encryption_configuration" "infrastructure_ecs_cluster_service_alb_logs" {
  count = local.enable_infrastructure_ecs_cluster_services_alb_logs ? 1 : 0

  bucket = aws_s3_bucket.infrastructure_ecs_cluster_service_alb_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "infrastructure_ecs_cluster_service_alb_logs" {
  count = local.enable_infrastructure_ecs_cluster_services_alb_logs && local.infrastructure_ecs_cluster_services_alb_logs_retention != 0 ? 1 : 0

  bucket = aws_s3_bucket.infrastructure_ecs_cluster_service_alb_logs[0].id

  rule {
    id = "all_expire"

    filter {
      prefix = ""
    }

    expiration {
      days = local.infrastructure_ecs_cluster_services_alb_logs_retention
    }

    status = "Enabled"
  }
}
