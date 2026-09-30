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
    dynamic "allow" {
      for_each = each.value["default_action"] == "block" ? [] : [1]
      content {}
    }
    dynamic "block" {
      for_each = each.value["default_action"] == "block" ? [1] : []
      content {}
    }
  }
  custom_response_body {
    key          = "rate_limit_exceeded"
    content      = "You have exceeded the rate limit for this service. Please try again later."
    content_type = "TEXT_PLAIN"
  }

  dynamic "challenge_config" {
    for_each = each.value["challenge_immunity_time_sec"] != null ? [1] : []

    content {
      immunity_time_property {
        immunity_time = each.value["challenge_immunity_time_sec"]
      }
    }
  }

  dynamic "captcha_config" {
    for_each = each.value["captcha_immunity_time_sec"] != null ? [1] : []

    content {
      immunity_time_property {
        immunity_time = each.value["captcha_immunity_time_sec"]
      }
    }
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
      priority = 2 # IPv6 deny follows the IPv4 lists; managed rules start at 4

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
      priority = 3 # IPv6 allow follows the IPv6 deny; managed rules start at 4

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
    for_each = each.value["geo_rules"] != null ? each.value["geo_rules"] : []

    content {
      name     = rule.value["name"]
      priority = rule.key + 10 # Geo rules run before the managed groups so Bot Control never inspects challenged traffic

      action {
        dynamic "block" {
          for_each = rule.value["action"] == "block" ? [1] : []
          content {}
        }
        dynamic "challenge" {
          for_each = rule.value["action"] == "challenge" ? [1] : []
          content {}
        }
        dynamic "captcha" {
          for_each = rule.value["action"] == "captcha" ? [1] : []
          content {}
        }
        dynamic "count" {
          for_each = rule.value["action"] == "count" ? [1] : []
          content {}
        }
      }

      statement {
        dynamic "geo_match_statement" {
          for_each = !rule.value["negate"] && rule.value["excluded_path_regex"] == null ? [1] : []

          content {
            country_codes = rule.value["country_codes"]
          }
        }

        dynamic "not_statement" {
          for_each = rule.value["negate"] && rule.value["excluded_path_regex"] == null ? [1] : []

          content {
            statement {
              geo_match_statement {
                country_codes = rule.value["country_codes"]
              }
            }
          }
        }

        dynamic "and_statement" {
          for_each = rule.value["excluded_path_regex"] != null ? [1] : []

          content {
            statement {
              dynamic "geo_match_statement" {
                for_each = rule.value["negate"] ? [] : [1]

                content {
                  country_codes = rule.value["country_codes"]
                }
              }

              dynamic "not_statement" {
                for_each = rule.value["negate"] ? [1] : []

                content {
                  statement {
                    geo_match_statement {
                      country_codes = rule.value["country_codes"]
                    }
                  }
                }
              }
            }

            statement {
              not_statement {
                statement {
                  regex_match_statement {
                    regex_string = rule.value["excluded_path_regex"]

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

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${local.resource_prefix}-${each.key}-${rule.value["name"]}"
        sampled_requests_enabled   = true
      }
    }
  }
  dynamic "rule" {
    for_each = each.value["aws_managed_rules"] != null ? each.value["aws_managed_rules"] : []

    content {
      name     = rule.value["name"]
      priority = rule.key + 100 # Managed groups run after the IP sets and geo rules; scoped rate rules follow at 200

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

          dynamic "rule_action_override" {
            for_each = rule.value["challenge_rules"] != null ? rule.value["challenge_rules"] : []

            content {
              name = rule_action_override["value"]

              action_to_use {
                challenge {}
              }
            }
          }

          dynamic "rule_action_override" {
            for_each = rule.value["captcha_rules"] != null ? rule.value["captcha_rules"] : []

            content {
              name = rule_action_override["value"]

              action_to_use {
                captcha {}
              }
            }
          }

          dynamic "managed_rule_group_configs" {
            for_each = rule.value["bot_control_inspection_level"] != null ? [1] : []

            content {
              aws_managed_rules_bot_control_rule_set {
                inspection_level = rule.value["bot_control_inspection_level"]
                # The provider defaults this to true but AWS only honours it
                # for TARGETED and stores false for COMMON, which otherwise
                # leaves a permanent diff on the rule.
                enable_machine_learning = rule.value["bot_control_inspection_level"] == "TARGETED"
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
  dynamic "rule" {
    for_each = each.value["rate_rules"] != null ? each.value["rate_rules"] : []

    content {
      name     = rule.value["name"]
      priority = rule.key + 200 # Scoped rate rules run after the managed groups and before the site-wide RateLimit at 1000

      action {
        dynamic "block" {
          for_each = rule.value["action"] == "block" ? [1] : []

          content {
            custom_response {
              response_code            = 429
              custom_response_body_key = "rate_limit_exceeded"
            }
          }
        }
        dynamic "challenge" {
          for_each = rule.value["action"] == "challenge" ? [1] : []
          content {}
        }
        dynamic "captcha" {
          for_each = rule.value["action"] == "captcha" ? [1] : []
          content {}
        }
        dynamic "count" {
          for_each = rule.value["action"] == "count" ? [1] : []
          content {}
        }
      }

      statement {
        rate_based_statement {
          limit                 = rule.value["limit"]
          aggregate_key_type    = "IP"
          evaluation_window_sec = rule.value["evaluation_window_sec"]

          scope_down_statement {
            dynamic "regex_match_statement" {
              for_each = rule.value["methods"] == null ? [1] : []

              content {
                regex_string = rule.value["path_regex"]

                field_to_match {
                  uri_path {}
                }

                text_transformation {
                  priority = 0
                  type     = "NONE"
                }
              }
            }

            dynamic "and_statement" {
              for_each = rule.value["methods"] != null ? [1] : []

              content {
                statement {
                  regex_match_statement {
                    regex_string = rule.value["path_regex"]

                    field_to_match {
                      uri_path {}
                    }

                    text_transformation {
                      priority = 0
                      type     = "NONE"
                    }
                  }
                }

                statement {
                  regex_match_statement {
                    regex_string = "^(${join("|", rule.value["methods"])})$"

                    field_to_match {
                      method {}
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

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${local.resource_prefix}-${each.key}-${rule.value["name"]}"
        sampled_requests_enabled   = true
      }
    }
  }
  dynamic "rule" {
    for_each = each.value.rate_limiting != null && each.value.rate_limiting.enabled ? [1] : []
    content {
      name     = "RateLimit"
      priority = 1000 # Ensure this rule is processed last

      action {
        block {
          custom_response {
            response_code            = 429
            custom_response_body_key = "rate_limit_exceeded"
          }
        }
      }
      statement {
        rate_based_statement {
          limit                 = each.value.rate_limiting.limit
          aggregate_key_type    = "IP"
          evaluation_window_sec = each.value.rate_limiting.evaluation_window_sec
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${local.resource_prefix}-${each.key}-rate-limit"
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

