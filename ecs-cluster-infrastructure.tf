resource "aws_ecs_cluster" "infrastructure" {
  count = local.enable_infrastructure_ecs_cluster ? 1 : 0

  name = local.infrastructure_ecs_cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  dynamic "configuration" {
    for_each = local.infrastructure_ecs_cluster_enable_execute_command_logging ? [1] : []
    content {
      execute_command_configuration {
        kms_key_id = local.infrastructure_kms_encryption ? aws_kms_key.infrastructure[0].arn : null
        logging    = "OVERRIDE"

        log_configuration {
          s3_bucket_encryption_enabled = true
          s3_bucket_name               = aws_s3_bucket.infrastructure_logs[0].id
          s3_key_prefix                = "ecs-exec"
        }
      }
    }
  }
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

resource "aws_iam_policy" "infrastructure_ecs_cluster_s3_transfer_bucket_rw" {
  count = local.enable_infrastructure_vpc_transfer_s3_bucket ? 1 : 0

  name = "${local.resource_prefix}-s3-transfer-bucket-rw"
  policy = templatefile(
    "${path.root}/policies/s3-object-rw.json.tpl",
    {
      bucket_arn = aws_s3_bucket.infrastructure_vpc_transfer[0].arn
    }
  )
}

resource "aws_iam_role_policy_attachment" "infrastructure_ecs_cluster_s3_transfer_bucket_rw" {
  count = local.enable_infrastructure_vpc_transfer_s3_bucket ? 1 : 0

  role       = aws_iam_role.infrastructure_ecs_cluster[0].name
  policy_arn = aws_iam_policy.infrastructure_ecs_cluster_s3_transfer_bucket_rw[0].arn
}

resource "aws_iam_policy" "infrastructure_ecs_cluster_kms_encrypt" {
  count = local.infrastructure_ecs_cluster_allow_kms_encryption ? 1 : 0

  name = "${local.resource_prefix}-kms-encrypt"
  policy = templatefile(
    "${path.root}/policies/kms-encrypt.json.tpl",
    {
      kms_key_arn = aws_kms_key.infrastructure[0].arn
    }
  )
}

resource "aws_iam_role_policy_attachment" "infrastructure_ecs_cluster_kms_encrypt" {
  count = local.infrastructure_ecs_cluster_allow_kms_encryption ? 1 : 0

  role       = aws_iam_role.infrastructure_ecs_cluster[0].name
  policy_arn = aws_iam_policy.infrastructure_ecs_cluster_kms_encrypt[0].arn
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

  depends_on = [
    aws_efs_mount_target.infrastructure_ecs_cluster,
  ]
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

  enabled_metrics = [
    "GroupAndWarmPoolDesiredCapacity",
    "GroupAndWarmPoolTotalCapacity",
    "GroupDesiredCapacity",
    "GroupInServiceCapacity",
    "GroupInServiceInstances",
    "GroupMaxSize",
    "GroupMinSize",
    "GroupPendingCapacity",
    "GroupPendingInstances",
    "GroupStandbyCapacity",
    "GroupStandbyInstances",
    "GroupTerminatingCapacity",
    "GroupTerminatingInstances",
    "GroupTotalCapacity",
    "GroupTotalInstances",
    "WarmPoolDesiredCapacity",
    "WarmPoolMinSize",
    "WarmPoolPendingCapacity",
    "WarmPoolTerminatingCapacity",
    "WarmPoolTotalCapacity",
    "WarmPoolWarmedCapacity",
  ]

  depends_on = [
    aws_iam_role_policy_attachment.infrastructure_ecs_cluster_ec2_ecs,
    aws_iam_role_policy_attachment.infrastructure_ecs_cluster_s3_transfer_bucket_rw,
    aws_iam_role_policy_attachment.infrastructure_ecs_cluster_kms_encrypt,
  ]
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
