# Architecture Decision Records (ADRs)

This directory contains records of the significant architectural decisions made in the development of the dxw Dalmatian infrastructure Terraform module.

## Index

*   **[ADR 0001: Use EC2 for ECS instead of Fargate](0001-use-ec2-for-ecs-instead-of-fargate.md)** - Explains why we use EC2 instances for the main application cluster and our automated instance refresh strategy.
*   **[ADR 0002: Log Analytics via Athena and Glue Integration](0002-vpc-flow-logs-athena-integration.md)** - Details the serverless analytics stack for analyzing VPC and CloudFront logs.
*   **[ADR 0003: CloudFront Bypass Protection for ALB](0003-cloudfront-bypass-protection-for-alb.md)** - Documents the security mechanism to prevent bypassing the WAF and CDN.
*   **[ADR 0004: RDS Scheduled S3 Backups via Utilities Cluster](0004-rds-scheduled-s3-backups-via-ecs.md)** - Rationalizes the use of standard SQL dumps in S3 via a generalized utilities compute layer.
*   **[ADR 0005: Use SSM Session Manager for Bastion Host](0005-use-ssm-session-manager-for-bastion-host.md)** - Explains why we chose a stealth-mode bastion host without SSH.
*   **[ADR 0006: Centralized Infrastructure KMS Key](0006-centralized-infrastructure-kms-key.md)** - Documents the strategy of using a single infrastructure key with support for custom policy extensions.
*   **[ADR 0007: Automated Resource Tagging via Local-Exec](0007-automated-resource-tagging-via-local-exec.md)** - Explains how and why we enforce tagging via external scripts.
*   **[ADR 0008: Blue/Green Deployment Strategy with CodeDeploy for ECS](0008-blue-green-deployment-strategy-with-codedeploy-for-ecs.md)** - Rationalizes the zero-downtime deployment strategy.
*   **[ADR 0009: Use Fargate for Ephemeral Utilities Cluster](0009-use-fargate-for-ephemeral-utility-tasks.md)** - Details the secondary serverless cluster used for generalized infrastructure operations.
*   **[ADR 0010: Datadog as an Optional Experiment and Default Tooling](0010-datadog-as-an-optional-experiment-and-default-tooling.md)** - Documents the decision to retain Datadog code as an optional client feature after a successful but costly parallel experiment.
*   **[ADR 0011: S3 Private-by-Default and CloudFront OAC](0011-s3-private-by-default-and-cloudfront-oac.md)** - Standardizes on secure private object delivery.
*   **[ADR 0012: Defense-in-Depth via Mandatory Network ACLs](0012-defense-in-depth-via-mandatory-network-acls.md)** - Explains the two-layer network security model.
*   **[ADR 0013: Automated ECR Scanning and Vulnerability Alerting](0013-automated-ecr-scanning-and-vulnerability-alerting.md)** - Details the continuous image vulnerability scanning strategy.
*   **[ADR 0014: Global Accelerator for Apex Domain Routing](0014-global-accelerator-for-apex-domain-routing.md)** - Documents the solution for routing apex domains and global performance.
*   **[ADR 0015: S3-based Environment Configuration for ECS](0015-s3-based-environment-configuration-for-ecs.md)** - Rationalizes the use of S3 for bulk environment configuration files.
*   **[ADR 0016: Cross-Account DNS Delegation Pattern](0016-cross-account-dns-delegation-pattern.md)** - Details the automated pattern for root-to-environment DNS delegation.
*   **[ADR 0017: CloudFormation "Escape Hatch" Integration](0017-cloudformation-escape-hatch-integration.md)** - Documents the secure way to deploy custom templates via Terraform.
*   **[ADR 0018: Ephemeral VPC File Transfer Mechanism](0018-ephemeral-vpc-file-transfer-mechanism.md)** - Explains the secure S3/SSM document-based file transfer method.
*   **[ADR 0019: Multi-AZ Subnet and Route Table Topology](0019-multi-az-subnet-and-route-table-topology.md)** - Details the high-availability network design.
*   **[ADR 0020: Serverless-First Database and Cache Scaling](0020-serverless-first-database-and-cache-scaling.md)** - Rationalizes the preference for Aurora and ElastiCache Serverless.
*   **[ADR 0021: Custom Lambda Deployment Strategy](0021-custom-lambda-deployment-strategy.md)** - Explains the "Plumbing and Placeholder" strategy for managing Lambda functions.
*   **[ADR 0022: Resource Naming and Prefixing Strategy](0022-resource-naming-and-prefixing-strategy.md)** - Documents the hierarchical prefixing and hashing pattern for resource identification.
*   **[ADR 0023: Unified CloudWatch Alerting Architecture](0023-unified-cloudwatch-alerting-architecture.md)** - Rationalizes the centralized SNS-based alerting hub for operational tools.
*   **[ADR 0024: Standardized S3 Log Delivery and Retention](0024-standardized-s3-log-delivery-and-retention.md)** - Details the consolidated "Infrastructure Logs" bucket strategy.
*   **[ADR 0025: Externalized Templated IAM Policies](0025-externalized-templated-iam-policies.md)** - Documents the move to `.json.tpl` files for better policy management and readability.
*   **[ADR 0026: Multi-Region ACM for Global Services (CloudFront)](0026-multi-region-acm-for-global-services-cloudfront.md)** - Explains why and how we provision certificates in `us-east-1` for global distributions.
*   **[ADR 0027: Bridging Terraform Gaps with External Data Scripts](0027-bridging-terraform-gaps-with-external-data-scripts.md)** - Rationalizes the use of the `external` data source for specialized AWS API logic.
*   **[ADR 0028: Shared Persistent Storage via Amazon EFS](0028-shared-persistent-storage-via-amazon-efs.md)** - Documents the decision to use EFS for multi-node persistent container storage.
*   **[ADR 0029: Automated Master Password Management via Secrets Manager](0029-automated-master-password-management-via-secrets-manager.md)** - Details the native RDS password escrow and management strategy.
*   **[ADR 0030: Tiered Storage Lifecycle Policies for Cost Management](0030-tiered-storage-lifecycle-policies-for-cost-management.md)** - Explains the automated data aging and expiration strategy across the platform.