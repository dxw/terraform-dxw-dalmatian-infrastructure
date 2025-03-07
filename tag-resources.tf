resource "terraform_data" "tag_resources" {
  for_each = local.custom_resource_tags

  triggers_replace = [
    timestamp()
  ]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOF
      ${path.root}/local-exec-scripts/tag-resources.sh \
      -a ${each.value["arns"]} \
      -t '${jsonencode(each.value["tags"])}' \
      -d ${local.custom_resource_tags_delay}
    EOF
  }
}
