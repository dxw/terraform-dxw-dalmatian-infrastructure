# Pick a random hour between 00 & 06 for use in a Cron expression
resource "random_integer" "infrastructure_rds_daily_backups_hour" {
  for_each = local.infrastructure_rds_backups_enabled

  min = 0
  max = 6
  keepers = {
    # Generate a new value if the db instance changes
    listener_arn = aws_db_instance.infrastructure_rds[each.key].arn
  }
}

# Define a scheduled event that runs at a random hour between 00:00-06:00
resource "aws_cloudwatch_event_rule" "infrastructure_rds_daily_backups" {
  for_each = local.infrastructure_rds_backups_enabled

  name                = "${local.resource_prefix_hash}-${each.key}-rds-backups"
  description         = "Execute ${local.resource_prefix_hash}-${each.key}-rds-backups task at a scheduled time"
  schedule_expression = "cron(0 ${format("%g", random_integer.infrastructure_rds_daily_backups_hour[each.key].result)} * * ? *)"
}

# When the Cloudwatch event fires, invoke the new Task Definition
resource "aws_cloudwatch_event_target" "infrastructure_rds_daily_backups" {
  for_each = local.enable_infrastructure_ecs_cluster == true ? local.infrastructure_rds_backups_enabled : {}

  target_id = "${local.resource_prefix_hash}-${each.key}-rds-backups-target"
  rule      = aws_cloudwatch_event_rule.infrastructure_rds_daily_backups[each.key].name
  arn       = aws_ecs_cluster.infrastructure[0].arn
  # role_arn  = aws_iam_role.infrastructure_rds_daily_backups_cloudwatch.arn
  input = jsonencode({})

  ecs_target {
    launch_type         = "EC2"
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.infrastructure_rds_daily_backups[each.key].arn
  }
}
