output "resource_map" {
  description = "Simplified map of resources and their dependencies, associations and attachments"
  value = {
    vpc = {
      _description  = "VPC parameters and network resources"
      enabled       = local.infrastructure_vpc
      id            = local.infrastructure_vpc ? aws_vpc.infrastructure[0].id : null
      name          = local.infrastructure_vpc ? aws_vpc.infrastructure[0].tags["Name"] : null
      cidr_block    = local.infrastructure_vpc ? local.infrastructure_vpc_cidr_block : null
      dns           = local.infrastructure_vpc ? local.infrastructure_vpc_enable_dns_support : null
      dns_hostnames = local.infrastructure_vpc ? local.infrastructure_vpc_enable_dns_hostnames : null
      ipv6          = local.infrastructure_vpc ? local.infrastructure_vpc_assign_generated_ipv6_cidr_block : null
      flow_logs = {
        enabled        = local.infrastructure_vpc ? local.infrastructure_vpc_flow_logs_cloudwatch_logs : null
        traffic_type   = local.infrastructure_vpc ? local.infrastructure_vpc_flow_logs_traffic_type : null
        s3_destination = local.infrastructure_vpc_flow_logs_s3_with_athena ? "${aws_s3_bucket.infrastructure_logs[0].arn}/${local.infrastructure_vpc_flow_logs_s3_key_prefix}" : null
        cloudwatch = {
          log_group_name      = local.infrastructure_vpc_flow_logs_cloudwatch_logs ? aws_cloudwatch_log_group.infrastructure_vpc_flow_logs[0].name : null
          log_group_retention = local.infrastructure_vpc_flow_logs_cloudwatch_logs ? local.infrastructure_vpc_flow_logs_retention : null
        }
        athena = {
          enabled                = local.infrastructure_vpc_flow_logs_s3_with_athena
          workgroup_name         = local.infrastructure_vpc_flow_logs_s3_with_athena ? aws_athena_workgroup.infrastructure_vpc_flow_logs[0].name : null
          result_output_location = local.infrastructure_vpc_flow_logs_s3_with_athena ? aws_athena_workgroup.infrastructure_vpc_flow_logs[0].configuration[0].result_configuration[0].output_location : null
        }
      }
      networking = {
        private = {
          enabled = local.infrastructure_vpc_network_enable_private
          subnets = local.infrastructure_vpc_network_enable_private ? {
            for subnet in aws_subnet.infrastructure_private : subnet.id => {
              availability_zone = subnet.availability_zone
              cidr_block        = subnet.cidr_block
              name              = subnet.tags["Name"]
            }
          } : null
          route_table = {
            id   = local.infrastructure_vpc_network_enable_private ? aws_route_table.infrastructure_private[0].id : null
            name = local.infrastructure_vpc_network_enable_private ? aws_route_table.infrastructure_private[0].tags["Name"] : null
            routes = local.infrastructure_vpc_network_enable_private ? {
              for route in aws_route_table.infrastructure_private[0].route : coalesce(route.cidr_block, route.ipv6_cidr_block, route.destination_prefix_list_id) => [
                for k, v in route : {
                  target_type = k
                  target_id   = v
                } if !contains(["cidr_block", "destination_prefix_list_id", "ipv6_cidr_block"], k) && v != ""
              ][0]
            } : null
            subnet_associations = local.infrastructure_vpc_network_enable_private ? [
              for association in aws_route_table_association.infrastructure_private : association.subnet_id
            ] : null
          }
          nat_gateway = {
            enabled          = local.infrastructure_vpc_network_enable_private && local.infrastructure_vpc_network_enable_public
            public_ip        = local.infrastructure_vpc_network_enable_private && local.infrastructure_vpc_network_enable_public ? aws_eip.infrastructure_nat[0].public_ip : null
            public_subnet_id = local.infrastructure_vpc_network_enable_private && local.infrastructure_vpc_network_enable_public ? aws_nat_gateway.infrastructure[0].subnet_id : null
          }
        }
        public = {
          enabled = local.infrastructure_vpc_network_enable_public
          subnets = local.infrastructure_vpc_network_enable_public ? {
            for subnet in aws_subnet.infrastructure_public : subnet.id => {
              availability_zone = subnet.availability_zone
              cidr_block        = subnet.cidr_block
              name              = subnet.tags["Name"]
            }
          } : null
          route_table = {
            id   = local.infrastructure_vpc_network_enable_public ? aws_route_table.infrastructure_public[0].id : null
            name = local.infrastructure_vpc_network_enable_public ? aws_route_table.infrastructure_public[0].tags["Name"] : null
            routes = local.infrastructure_vpc_network_enable_public ? {
              for route in aws_route_table.infrastructure_public[0].route : coalesce(route.cidr_block, route.ipv6_cidr_block, route.destination_prefix_list_id) => [
                for k, v in route : {
                  target_type = k
                  target_id   = v
                } if !contains(["cidr_block", "destination_prefix_list_id", "ipv6_cidr_block"], k) && v != ""
              ][0]
            } : null
            subnet_associations = local.infrastructure_vpc_network_enable_public ? [
              for association in aws_route_table_association.infrastructure_public : association.subnet_id
            ] : null
          }
        }
      }
    }
    kms = {
      _description = "KMS encryption for all relevent resources that can optionally use CMK for encryption"
      enabled      = local.infrastructure_kms_encryption
      key_arn      = local.infrastructure_kms_encryption ? aws_kms_key.infrastructure[0].arn : null
      key_alias    = local.infrastructure_kms_encryption ? aws_kms_alias.infrastructure[0].name : null
    }
    logs_bucket = {
      _descripion = "S3 bucket to store logs for all resources that produce logs. This is only enabled when required."
      enabled     = local.enable_infrastructure_logs_bucket
      name        = local.enable_infrastructure_logs_bucket ? aws_s3_bucket.infrastructure_logs[0].bucket : null
      retention   = local.enable_infrastructure_logs_bucket ? local.infrastructure_logging_bucket_retention : null
    }
    route53_hosted_zone = {
      _description = "Route53 hosted zone for resources that that are compatible with DNS records"
      enabled      = local.enable_infrastructure_route53_hosted_zone
      name         = local.enable_infrastructure_route53_hosted_zone ? aws_route53_zone.infrastructure[0].name : null
      id           = local.enable_infrastructure_route53_hosted_zone ? aws_route53_zone.infrastructure[0].zone_id : null
      ns_records = local.enable_infrastructure_route53_hosted_zone ? [
        aws_route53_zone.infrastructure[0].name_servers[0],
        aws_route53_zone.infrastructure[0].name_servers[1],
        aws_route53_zone.infrastructure[0].name_servers[2],
        aws_route53_zone.infrastructure[0].name_servers[3],
      ] : null
      ns_delegation = {
        zone_name = local.create_infrastructure_route53_delegations ? data.aws_route53_zone.root[0].name : null
        zone_id   = local.create_infrastructure_route53_delegations ? data.aws_route53_zone.root[0].zone_id : null
      }
    }
    ecs_cluster = {
      _description = "ECS Cluster and EC2 resources"
      enabled      = local.enable_infrastructure_ecs_cluster
      name         = local.enable_infrastructure_ecs_cluster ? aws_ecs_cluster.infrastructure[0].name : null
      ec2_instances = {
        launch_template_name   = local.enable_infrastructure_ecs_cluster ? aws_launch_template.infrastructure_ecs_cluster[0].name : null
        autoscaling_group_name = local.enable_infrastructure_ecs_cluster ? aws_autoscaling_group.infrastructure_ecs_cluster[0].name : null
        public_availability    = local.enable_infrastructure_ecs_cluster ? local.infrastructure_ecs_cluster_publicly_avaialble : null
        security_groups        = local.enable_infrastructure_ecs_cluster ? aws_launch_template.infrastructure_ecs_cluster[0].network_interfaces[0].security_groups : null
        ami_id                 = local.enable_infrastructure_ecs_cluster ? aws_launch_template.infrastructure_ecs_cluster[0].image_id : null
        type                   = local.enable_infrastructure_ecs_cluster ? aws_launch_template.infrastructure_ecs_cluster[0].instance_type : null
        min_size               = local.enable_infrastructure_ecs_cluster ? aws_autoscaling_group.infrastructure_ecs_cluster[0].min_size : null
        max_size               = local.enable_infrastructure_ecs_cluster ? aws_autoscaling_group.infrastructure_ecs_cluster[0].max_size : null
        max_instance_lifetime  = local.enable_infrastructure_ecs_cluster ? aws_autoscaling_group.infrastructure_ecs_cluster[0].max_instance_lifetime : null
        termination_lifecycle = {
          timeout        = local.enable_infrastructure_ecs_cluster ? aws_autoscaling_lifecycle_hook.infrastructure_ecs_cluster_termination[0].heartbeat_timeout : null
          sns_target_arn = local.enable_infrastructure_ecs_cluster ? aws_autoscaling_lifecycle_hook.infrastructure_ecs_cluster_termination[0].notification_target_arn : null
          instance_draining_lambda = {
            enabled       = local.infrastructure_ecs_cluster_draining_lambda_enabled
            role          = local.infrastructure_ecs_cluster_draining_lambda_enabled ? aws_iam_role.ecs_cluster_infrastructure_draining_lambda[0].name : null
            function_name = local.infrastructure_ecs_cluster_draining_lambda_enabled ? aws_lambda_function.ecs_cluster_infrastructure_draining[0].function_name : null
            log_retention = local.infrastructure_ecs_cluster_draining_lambda_enabled ? local.infrastructure_ecs_cluster_draining_lambda_log_retention : null
          }
        }
      }
    }
    efs = {
      _description     = "EFS resources"
      enabled          = local.enable_infrastructure_ecs_cluster_efs
      transition_to_ia = local.enable_infrastructure_ecs_cluster_efs && local.ecs_cluster_efs_infrequent_access_transition != 0 ? aws_efs_file_system.infrastructure_ecs_cluster[0].lifecycle_policy[0].transition_to_ia : null
      performance_mode = local.enable_infrastructure_ecs_cluster_efs ? aws_efs_file_system.infrastructure_ecs_cluster[0].performance_mode : null
      throughput_mode  = local.enable_infrastructure_ecs_cluster_efs ? aws_efs_file_system.infrastructure_ecs_cluster[0].throughput_mode : null
      dns_name         = local.enable_infrastructure_ecs_cluster_efs ? aws_efs_file_system.infrastructure_ecs_cluster[0].dns_name : null
      mount_targets = {
        for mount_target in aws_efs_mount_target.infrastructure_ecs_cluster : mount_target.subnet_id => mount_target.availability_zone_name
      }
      security_groups = local.enable_infrastructure_ecs_cluster_efs && (local.infrastructure_vpc_network_enable_private || local.infrastructure_vpc_network_enable_public) ? [
        for mount_target in aws_efs_mount_target.infrastructure_ecs_cluster : mount_target.security_groups
      ][0] : null
    }
  }
}
