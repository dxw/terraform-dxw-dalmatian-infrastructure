resource "aws_kms_key" "infrastructure_rds" {
  for_each = {
    for k, v in local.infrastructure_rds : k => v if v["dedicated_kms_key"] == true
  }

  description             = "${local.resource_prefix} ${each.key} RDS kms key"
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
  )}${each.value["dedicated_kms_key_policy_statements"] != null ? ",${each.value["dedicated_kms_key_policy_statements"]}" : ""}
      ]
      EOT
}
)
}

resource "aws_kms_alias" "infrastructure_rds" {
  for_each = {
    for k, v in local.infrastructure_rds : k => v if v["dedicated_kms_key"] == true
  }

  name          = "alias/${local.resource_prefix}-${each.key}-rds"
  target_key_id = aws_kms_key.infrastructure_rds[each.key].key_id
}
