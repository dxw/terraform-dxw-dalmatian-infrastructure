resource "aws_kms_key" "infrastructure" {
  count = local.infrastructure_kms_encryption ? 1 : 0

  description             = "${local.resource_prefix} infrastructure kms key"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = templatefile(
    "${path.root}/policies/kms-key-policy.json.tpl",
    {
      statement = <<EOT
      [
      ${templatefile("${path.root}/policies/kms-key-policy-statements/root-allow-all.json.tpl",
      {
        aws_account_id = local.aws_account_id
      }
  )}
      ]
      EOT
}
)
}

resource "aws_kms_alias" "infrastructure" {
  count = local.infrastructure_kms_encryption ? 1 : 0

  name          = "alias/${local.resource_prefix}-infrastructure"
  target_key_id = aws_kms_key.infrastructure[0].key_id
}
