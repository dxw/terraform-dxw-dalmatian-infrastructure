resource "aws_ecs_cluster" "infrastructure" {
  count = local.enable_infrastructure_ecs_cluster ? 1 : 0

  name = local.infrastructure_ecs_cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_security_group" "infrastructure_ecs_cluster_container_instances" {
  count = local.enable_infrastructure_ecs_cluster ? 1 : 0

  name        = "${local.resource_prefix}-infrastructure-ecs-cluster-container-instances"
  description = "Infrastructure ECS cluster container instances"
  vpc_id      = aws_vpc.infrastructure[0].id
}

resource "aws_security_group_rule" "infrastructure_ecs_cluster_container_instances_ingress_tcp" {
  count = local.enable_infrastructure_ecs_cluster && local.infrastructure_vpc_network_enable_public ? 1 : 0

  description = "Allow container port tcp ingress from public subnet (TO BE CHANGED TO ONLY ALLOW ALB)"
  type        = "ingress"
  from_port   = 32768
  to_port     = 65535
  protocol    = "tcp"
  # TODO: Update to `source_security_group_id`, using the ECS service ALB's security group id
  cidr_blocks       = [for subnet in aws_subnet.infrastructure_public : subnet.cidr_block]
  security_group_id = aws_security_group.infrastructure_ecs_cluster_container_instances[0].id
}

resource "aws_security_group_rule" "infrastructure_ecs_cluster_container_instances_ingress_udp" {
  count = local.enable_infrastructure_ecs_cluster && local.infrastructure_vpc_network_enable_public ? 1 : 0

  description = "Allow container port udp ingress from public subnet (TO BE CHANGED TO ONLY ALLOW ALB)"
  type        = "ingress"
  from_port   = 32768
  to_port     = 65535
  protocol    = "udp"
  # TODO: Update to `source_security_group_id`, using the ECS service ALB's security group id
  cidr_blocks       = [for subnet in aws_subnet.infrastructure_public : subnet.cidr_block]
  security_group_id = aws_security_group.infrastructure_ecs_cluster_container_instances[0].id
}

resource "aws_security_group_rule" "infrastructure_ecs_cluster_container_instances_egress_https_tcp" {
  count = local.enable_infrastructure_ecs_cluster ? 1 : 0

  description = "Allow HTTPS tcp outbound"
  type        = "egress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  # tfsec:ignore:aws-ec2-no-public-egress-sgr
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.infrastructure_ecs_cluster_container_instances[0].id
}

resource "aws_security_group_rule" "infrastructure_ecs_cluster_container_instances_egress_https_udp" {
  count = local.enable_infrastructure_ecs_cluster ? 1 : 0

  description = "Allow HTTPS udp outbound"
  type        = "egress"
  from_port   = 443
  to_port     = 443
  protocol    = "udp"
  # tfsec:ignore:aws-ec2-no-public-egress-sgr
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.infrastructure_ecs_cluster_container_instances[0].id
}

resource "aws_security_group_rule" "infrastructure_ecs_cluster_container_instances_egress_dns_tcp" {
  count = local.enable_infrastructure_ecs_cluster ? 1 : 0

  description = "Allow DNS tcp outbound to AWS"
  type        = "egress"
  from_port   = 53
  to_port     = 53
  protocol    = "tcp"
  cidr_blocks = local.infrastructure_ecs_cluster_publicly_avaialble ? [
    for subnet in aws_subnet.infrastructure_public : subnet.cidr_block
    ] : [
    for subnet in aws_subnet.infrastructure_private : subnet.cidr_block
  ]
  security_group_id = aws_security_group.infrastructure_ecs_cluster_container_instances[0].id
}

resource "aws_security_group_rule" "infrastructure_ecs_cluster_container_instances_egress_dns_udp" {
  count = local.enable_infrastructure_ecs_cluster ? 1 : 0

  description = "Allow DNS udp outbound to AWS"
  type        = "egress"
  from_port   = 53
  to_port     = 53
  protocol    = "udp"
  cidr_blocks = local.infrastructure_ecs_cluster_publicly_avaialble ? [
    for subnet in aws_subnet.infrastructure_public : subnet.cidr_block
    ] : [
    for subnet in aws_subnet.infrastructure_private : subnet.cidr_block
  ]
  security_group_id = aws_security_group.infrastructure_ecs_cluster_container_instances[0].id
}

resource "aws_iam_role" "infrastructure_ecs_cluster" {
  count = local.enable_infrastructure_ecs_cluster ? 1 : 0

  name        = "${local.resource_prefix}-${substr(sha512("infrastructure-ecs-cluster"), 0, 6)}"
  description = "${local.resource_prefix}-infrastructure-ecs-cluster"
  assume_role_policy = templatefile(
    "${path.root}/policies/assume-roles/service-principle-standard.json.tpl",
    { services = jsonencode(["ecs.amazonaws.com", "ec2.amazonaws.com"]) }
  )
}

resource "aws_iam_policy" "infrastructure_ecs_cluster_ec2_ecs" {
  count = local.enable_infrastructure_ecs_cluster ? 1 : 0

  name   = "${local.resource_prefix}-ec2-ecs"
  policy = templatefile("${path.root}/policies/ec2-ecs.json.tpl", {})
}

resource "aws_iam_role_policy_attachment" "infrastructure_ecs_cluster_ec2_ecs" {
  count = local.enable_infrastructure_ecs_cluster ? 1 : 0

  role       = aws_iam_role.infrastructure_ecs_cluster[0].name
  policy_arn = aws_iam_policy.infrastructure_ecs_cluster_ec2_ecs[0].arn
}

resource "aws_iam_instance_profile" "infrastructure_ecs_cluster" {
  count = local.enable_infrastructure_ecs_cluster ? 1 : 0

  name = "${local.resource_prefix}-infrastructure-ecs-cluster"
  role = aws_iam_role.infrastructure_ecs_cluster[0].name
}

resource "aws_launch_template" "infrastructure_ecs_cluster" {
  count = local.enable_infrastructure_ecs_cluster ? 1 : 0

  name        = "${local.resource_prefix}-infrastructure-ecs-cluster"
  description = "Infrastructure ECS Cluster (${local.resource_prefix})"

  block_device_mappings {
    # Root EBS volume
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 40
      encrypted             = true
      delete_on_termination = true
    }
  }

  block_device_mappings {
    # Docker Storage EBS volume
    device_name = local.infrastructure_ecs_cluster_ebs_docker_storage_volume_device_name

    ebs {
      volume_size           = local.infrastructure_ecs_cluster_ebs_docker_storage_volume_size
      volume_type           = local.infrastructure_ecs_cluster_ebs_docker_storage_volume_type
      encrypted             = true
      delete_on_termination = true
    }
  }

  capacity_reservation_specification {
    capacity_reservation_preference = "open"
  }

  network_interfaces {
    associate_public_ip_address = local.infrastructure_ecs_cluster_publicly_avaialble
    security_groups             = [aws_security_group.infrastructure_ecs_cluster_container_instances[0].id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.infrastructure_ecs_cluster[0].name
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  monitoring {
    enabled = true
  }

  disable_api_termination              = false
  disable_api_stop                     = false
  ebs_optimized                        = true
  image_id                             = data.aws_ami.ecs_cluster_ami[0].id
  instance_initiated_shutdown_behavior = "stop"
  instance_type                        = local.infrastructure_ecs_cluster_instance_type

  user_data = local.infrastructure_ecs_cluster_user_data
}

resource "aws_placement_group" "infrastructure_ecs_cluster" {
  count = local.enable_infrastructure_ecs_cluster ? 1 : 0

  name = "${local.resource_prefix}-infrastructure-ecs-cluster"

  strategy     = "spread"
  spread_level = "rack"
}

resource "aws_autoscaling_group" "infrastructure_ecs_cluster" {
  count = local.enable_infrastructure_ecs_cluster ? 1 : 0

  name = "${local.resource_prefix}-infrastructure-ecs-cluster"

  launch_template {
    id      = aws_launch_template.infrastructure_ecs_cluster[0].id
    version = aws_launch_template.infrastructure_ecs_cluster[0].latest_version
  }

  vpc_zone_identifier = local.infrastructure_ecs_cluster_publicly_avaialble ? [
    for subnet in aws_subnet.infrastructure_public : subnet.id
    ] : [
    for subnet in aws_subnet.infrastructure_private : subnet.id
  ]
  placement_group = aws_placement_group.infrastructure_ecs_cluster[0].id

  min_size              = local.infrastructure_ecs_cluster_min_size
  max_size              = local.infrastructure_ecs_cluster_max_size
  desired_capacity      = local.infrastructure_ecs_cluster_min_size
  max_instance_lifetime = local.infrastructure_ecs_cluster_max_instance_lifetime

  termination_policies = ["OldestLaunchConfiguration", "ClosestToNextInstanceHour", "Default"]

  tag {
    key                 = "Name"
    value               = "${local.resource_prefix}-infrastructure-ecs-cluster"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = local.default_tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 100
    }
    triggers = ["tag"]
  }

  timeouts {
    delete = "15m"
  }
}

resource "aws_sns_topic" "infrastructure_ecs_cluster_autoscaling_lifecycle_termination" {
  count = local.enable_infrastructure_ecs_cluster ? 1 : 0

  name              = "${local.resource_prefix}-ecs-termination-hook"
  kms_master_key_id = local.infrastructure_kms_encryption ? aws_kms_alias.infrastructure[0].name : null
}

resource "aws_iam_role" "infrastructure_ecs_cluster_autoscaling_lifecycle_termination" {
  count = local.enable_infrastructure_ecs_cluster ? 1 : 0

  name        = "${local.resource_prefix}-${substr(sha512("ecs-termination-hook"), 0, 6)}"
  description = "${local.resource_prefix}-ecs-termination-hook"
  assume_role_policy = templatefile(
    "${path.root}/policies/assume-roles/service-principle-standard.json.tpl",
    { services = jsonencode(["autoscaling.amazonaws.com"]) }
  )
}

resource "aws_iam_policy" "infrastructure_ecs_cluster_autoscaling_lifecycle_termination_sns_publish" {
  count = local.enable_infrastructure_ecs_cluster ? 1 : 0

  name = "${local.resource_prefix}-ecs-termination-hook-sns-publish"
  policy = templatefile(
    "${path.root}/policies/sns-publish.json.tpl",
    { sns_topic_arn = aws_sns_topic.infrastructure_ecs_cluster_autoscaling_lifecycle_termination[0].arn }
  )
}

resource "aws_iam_role_policy_attachment" "infrastructure_ecs_cluster_autoscaling_lifecycle_termination_sns_publish" {
  count = local.enable_infrastructure_ecs_cluster ? 1 : 0

  role       = aws_iam_role.infrastructure_ecs_cluster_autoscaling_lifecycle_termination[0].id
  policy_arn = aws_iam_policy.infrastructure_ecs_cluster_autoscaling_lifecycle_termination_sns_publish[0].arn
}

resource "aws_iam_policy" "infrastructure_ecs_cluster_autoscaling_lifecycle_termination_kms_encrypt" {
  count = local.enable_infrastructure_ecs_cluster && local.infrastructure_kms_encryption ? 1 : 0

  name = "${local.resource_prefix}-ecs-termination-hook-kms-encrypt"
  policy = templatefile(
    "${path.root}/policies/kms-encrypt.json.tpl",
    { kms_key_arn = aws_kms_key.infrastructure[0].arn }
  )
}

resource "aws_iam_role_policy_attachment" "infrastructure_ecs_cluster_autoscaling_lifecycle_termination_kms_encrypt" {
  count = local.enable_infrastructure_ecs_cluster && local.infrastructure_kms_encryption ? 1 : 0

  role       = aws_iam_role.infrastructure_ecs_cluster_autoscaling_lifecycle_termination[0].id
  policy_arn = aws_iam_policy.infrastructure_ecs_cluster_autoscaling_lifecycle_termination_kms_encrypt[0].arn
}

resource "aws_autoscaling_lifecycle_hook" "infrastructure_ecs_cluster_termination" {
  count = local.enable_infrastructure_ecs_cluster ? 1 : 0

  name                    = local.infrastructure_ecs_cluster_termination_sns_topic_name
  autoscaling_group_name  = aws_autoscaling_group.infrastructure_ecs_cluster[0].name
  default_result          = local.infrastructure_ecs_cluster_draining_lambda_enabled ? "ABANDON" : "CONTINUE"
  heartbeat_timeout       = local.infrastructure_ecs_cluster_termination_timeout
  lifecycle_transition    = "autoscaling:EC2_INSTANCE_TERMINATING"
  role_arn                = aws_iam_role.infrastructure_ecs_cluster_autoscaling_lifecycle_termination[0].arn
  notification_target_arn = aws_sns_topic.infrastructure_ecs_cluster_autoscaling_lifecycle_termination[0].arn
}
