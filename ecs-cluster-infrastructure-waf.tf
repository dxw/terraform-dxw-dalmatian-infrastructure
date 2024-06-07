resource "aws_wafv2_ip_set" "infrastructure_ecs_cluster_ip_deny_list" {
  for_each = {
    for k, v in local.infrastructure_ecs_cluster_wafs : k => v if v["ip_deny_list"] != null
  }

  name               = "${local.resource_prefix}-${each.key}-ip-deny-list"
  description        = "IP addresses to block on ${local.resource_prefix}-${each.key}"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = each.value["ip_deny_list"]
}

resource "aws_wafv2_web_acl" "infrastructure_ecs_cluster" {
  for_each = local.infrastructure_ecs_cluster_wafs

  provider = aws.useast1

  name        = "${local.resource_prefix}-${each.key}"
  description = "${local.resource_prefix} ${each.key}"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  dynamic "rule" {
    for_each = each.value["ip_deny_list"] != null ? [1] : []

    content {
      name     = "CustomDalmatianBlockIPSet"
      priority = 0 # Always process this rule before any others if it is defined

      action {
        block {}
      }

      statement {
        ip_set_reference_statement {
          arn = aws_wafv2_ip_set.infrastructure_ecs_cluster_ip_deny_list[each.key].arn
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${local.resource_prefix}-${each.key}-ip-deny"
        sampled_requests_enabled   = true
      }
    }
  }

  dynamic "rule" {
    for_each = each.value["aws_managed_rules"] != null ? each.value["aws_managed_rules"] : []

    content {
      name     = rule.value["name"]
      priority = rule.key + 1

      override_action {
        dynamic "count" {
          for_each = rule.value["action"] == "count" ? [1] : []

          content {}
        }
        dynamic "none" {
          for_each = rule.value["action"] == "allow" ? [1] : rule.value["action"] == "block" ? [1] : []

          content {}
        }
      }

      statement {
        managed_rule_group_statement {
          name        = rule.value["name"]
          vendor_name = "AWS"

          dynamic "rule_action_override" {
            for_each = rule.value["exclude_rules"] != null ? rule.value["exclude_rules"] : []

            content {
              name = rule_action_override["value"]

              action_to_use {
                count {}
              }
            }
          }

          dynamic "scope_down_statement" {
            for_each = rule.value["excluded_path_patterns"] != null ? length(rule.value["excluded_path_patterns"]) > 0 ? [1] : [] : []
            content {
              not_statement {
                /* Avoid generarting an or_statement if we don't need one. */
                dynamic "statement" {
                  for_each = length(rule.value["excluded_path_patterns"]) == 1 ? [1] : []
                  content {
                    byte_match_statement {
                      positional_constraint = "CONTAINS"
                      search_string         = rule.value["excluded_path_patterns"][0]
                      field_to_match {
                        uri_path {}
                      }
                      text_transformation {
                        priority = 0
                        type     = "NONE"
                      }
                    }
                  }
                }
                dynamic "statement" {
                  for_each = length(rule.value["excluded_path_patterns"]) > 1 ? [1] : []
                  content {
                    or_statement {
                      dynamic "statement" {
                        for_each = rule.value["excluded_path_patterns"]
                        content {
                          byte_match_statement {
                            positional_constraint = "CONTAINS"
                            search_string         = statement.value
                            field_to_match {
                              uri_path {}
                            }
                            text_transformation {
                              priority = 0
                              type     = "NONE"
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${local.resource_prefix}-${each.key}-${rule.value["name"]}"
        sampled_requests_enabled   = true
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.resource_prefix}-${each.key}"
    sampled_requests_enabled   = true
  }
}
