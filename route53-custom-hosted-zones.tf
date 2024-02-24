resource "aws_route53_zone" "custom" {
  for_each = local.custom_route53_hosted_zones

  name    = each.key
  comment = "${local.resource_prefix} ${each.key}"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route53_record" "custom_ns" {
  for_each = merge([
    for k, v in local.custom_route53_hosted_zones : {
      for ns_name, ns_record in v["ns_records"] : "${k}_${ns_name}" => merge(ns_record, { zone_name = k, name = ns_name })
    }
  ]...)

  name = each.value["name"]

  type = "NS"
  ttl  = each.value["ttl"]

  zone_id = aws_route53_zone.custom[each.value["zone_name"]].zone_id

  records = each.value["values"]
}

resource "aws_route53_record" "custom_a" {
  for_each = merge([
    for k, v in local.custom_route53_hosted_zones : {
      for a_name, a_record in v["a_records"] : "${k}_${a_name}" => merge(a_record, { zone_name = k, name = a_name })
    }
  ]...)

  name = each.value["name"]

  type = "A"
  ttl  = each.value["ttl"]

  zone_id = aws_route53_zone.custom[each.value["zone_name"]].zone_id

  records = each.value["values"]
}

resource "aws_route53_record" "custom_alias" {
  for_each = merge([
    for k, v in local.custom_route53_hosted_zones : {
      for alias_name, alias_records in v["alias_records"] : "${k}_${alias_name}" => merge(alias_records, { zone_name = k, name = alias_name })
    }
  ]...)

  name = each.value["name"]

  type = "A"

  zone_id = aws_route53_zone.custom[each.value["zone_name"]].zone_id

  alias {
    name                   = each.value["value"]
    zone_id                = each.value["zone_id"]
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "custom_cname" {
  for_each = merge([
    for k, v in local.custom_route53_hosted_zones : {
      for cname_name, cname_record in v["cname_records"] : "${k}_${cname_name}" => merge(cname_record, { zone_name = k, name = cname_name })
    }
  ]...)

  name = each.value["name"]

  type = "CNAME"
  ttl  = each.value["ttl"]

  zone_id = aws_route53_zone.custom[each.value["zone_name"]].zone_id

  records = each.value["values"]
}

resource "aws_route53_record" "custom_mx" {
  for_each = merge([
    for k, v in local.custom_route53_hosted_zones : {
      for mx_name, mx_record in v["mx_records"] : "${k}_${mx_name}" => merge(mx_record, { zone_name = k, name = mx_name })
    }
  ]...)

  name = each.value["name"]

  type = "MX"
  ttl  = each.value["ttl"]

  zone_id = aws_route53_zone.custom[each.value["zone_name"]].zone_id

  records = each.value["values"]
}

resource "aws_route53_record" "custom_txt" {
  for_each = merge([
    for k, v in local.custom_route53_hosted_zones : {
      for txt_name, txt_record in v["txt_records"] : "${k}_${txt_name}" => merge(txt_record, { zone_name = k, name = txt_name })
    }
  ]...)

  name = each.value["name"]

  type = "TXT"
  ttl  = each.value["ttl"]

  zone_id = aws_route53_zone.custom[each.value["zone_name"]].zone_id

  records = each.value["values"]
}
