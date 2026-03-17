# 4. RDS Scheduled S3 Backups via Utilities Cluster

Date: 2024-07-24

## Status

Accepted

## Context

AWS RDS provides robust automated snapshot capabilities for disaster recovery. However, snapshots are tied to the AWS ecosystem and can only be restored into another RDS instance. For certain compliance requirements, data portability, or analytical workflows, it is often necessary to have raw SQL dumps of the databases. 

We need a reliable, automated way to extract raw SQL dumps from our PostgreSQL and MySQL RDS instances and store them securely in S3. Initially designed as a specialized RDS tool, we realized this compute capability could be generalized for other maintenance tasks.

## Decision

We will provision **Scheduled ECS Fargate Tasks** within a generalized **Utilities Cluster** to execute raw database backups to S3.

The implementation:
*   Uses a generic **Utilities image** capable of running various maintenance tasks beyond just database connections.
*   An EventBridge (CloudWatch Events) cron rule is established to trigger the task on a scheduled basis.
*   The container runs custom entrypoints (`ecs-entrypoints/rds-s3-backups-*.txt.tpl`) that utilize native tools (`pg_dump` / `mysqldump`) to stream the backup directly into a secure S3 bucket.

## Consequences

**Positive:**
*   **Data Portability:** Provides standard SQL dumps that can be imported into local development environments or non-AWS databases.
*   **Extensibility:** The "Utilities" cluster and image can be used for other ad-hoc maintenance tasks (e.g., data migration, cleanup scripts) without creating new clusters.
*   **Serverless Execution:** Using Fargate means we do not consume resources on our main EC2 ECS cluster, and we only pay for the compute while the backup is actively running.

**Negative:**
*   **Performance Impact:** Running `pg_dump` or `mysqldump` can put a read load on the primary RDS instance during the backup window.
*   **Additional Moving Parts:** Adds more ECS Task definitions, EventBridge rules, and IAM roles to manage compared to purely relying on native RDS snapshots.