resource "aws_wafv2_ip_set" "infrastructure_ecs_cluster_ipv4_deny_list" {
  for_each = {
    for k, v in local.infrastructure_ecs_cluster_wafs : k => v if v["ipv4_deny_list"] != null
  }

  name               = "${local.resource_prefix}-${each.key}-ipv4-deny-list"
  description        = "IPv4 addresses to block on ${local.resource_prefix}-${each.key}"
  provider           = aws.useast1
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = each.value["ipv4_deny_list"]
}

resource "aws_wafv2_ip_set" "infrastructure_ecs_cluster_ipv4_allow_list" {
  for_each = {
    for k, v in local.infrastructure_ecs_cluster_wafs : k => v if v["ipv4_allow_list"] != null
  }

  name               = "${local.resource_prefix}-${each.key}-ip-allow-list"
  description        = "IP addresses to allow on ${local.resource_prefix}-${each.key}"
  provider           = aws.useast1
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = each.value["ipv4_allow_list"]
}

resource "aws_wafv2_ip_set" "infrastructure_ecs_cluster_ipv6_deny_list" {
  for_each = {
    for k, v in local.infrastructure_ecs_cluster_wafs : k => v if v["ipv6_deny_list"] != null
  }

  name               = "${local.resource_prefix}-${each.key}-ipv6-deny-list"
  description        = "IPv6 addresses to block on ${local.resource_prefix}-${each.key}"
  provider           = aws.useast1
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV6"
  addresses          = each.value["ipv6_deny_list"]
}

resource "aws_wafv2_ip_set" "infrastructure_ecs_cluster_ipv6_allow_list" {
  for_each = {
    for k, v in local.infrastructure_ecs_cluster_wafs : k => v if v["ipv6_allow_list"] != null
  }

  name               = "${local.resource_prefix}-${each.key}-ipv6-allow-list"
  description        = "IPv6 addresses to allow on ${local.resource_prefix}-${each.key}"
  provider           = aws.useast1
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV6"
  addresses          = each.value["ipv6_allow_list"]
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
    for_each = each.value["ipv4_deny_list"] != null ? [1] : []

    content {
      name     = "CustomDalmatianBlockIPv4Set"
      priority = 0 # Always process this rule before any others if it is defined

      action {
        block {}
      }

      statement {
        ip_set_reference_statement {
          arn = aws_wafv2_ip_set.infrastructure_ecs_cluster_ipv4_deny_list[each.key].arn
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${local.resource_prefix}-${each.key}-ipv4-deny"
        sampled_requests_enabled   = true
      }
    }
  }
  dynamic "rule" {
    for_each = each.value["ipv4_allow_list"] != null ? [1] : []

    content {
      name     = "CustomDalmatianAllowIPv4Set"
      priority = 1 # Always process this rule before any others if it is defined

      action {
        allow {}
      }

      statement {
        ip_set_reference_statement {
          arn = aws_wafv2_ip_set.infrastructure_ecs_cluster_ipv4_allow_list[each.key].arn
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${local.resource_prefix}-${each.key}-ipv4-allow"
        sampled_requests_enabled   = true
      }
    }
  }

  dynamic "rule" {
    for_each = each.value["ipv6_deny_list"] != null ? [1] : []

    content {
      name     = "CustomDalmatianBlockIPv6Set"
      priority = 3 # Always process this rule before any others if it is defined

      action {
        block {}
      }

      statement {
        ip_set_reference_statement {
          arn = aws_wafv2_ip_set.infrastructure_ecs_cluster_ipv6_deny_list[each.key].arn
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${local.resource_prefix}-${each.key}-ipv6-deny"
        sampled_requests_enabled   = true
      }
    }
  }
  dynamic "rule" {
    for_each = each.value["ipv6_allow_list"] != null ? [1] : []

    content {
      name     = "CustomDalmatianAllowIPv6Set"
      priority = 4 # Always process this rule before any others if it is defined

      action {
        allow {}
      }

      statement {
        ip_set_reference_statement {
          arn = aws_wafv2_ip_set.infrastructure_ecs_cluster_ipv6_allow_list[each.key].arn
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${local.resource_prefix}-${each.key}-ipv6-allow"
        sampled_requests_enabled   = true
      }
    }
  }
  dynamic "rule" {
    for_each = each.value["aws_managed_rules"] != null ? each.value["aws_managed_rules"] : []

    content {
      name     = rule.value["name"]
      priority = rule.key + 4

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
