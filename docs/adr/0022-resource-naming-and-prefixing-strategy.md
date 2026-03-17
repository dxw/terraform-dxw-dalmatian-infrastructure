# 22. Resource Naming and Prefixing Strategy

Date: 2023-11-01

## Status

Accepted

## Context

AWS resources must be uniquely named within an account and region, and some resources (like S3 buckets) must be globally unique across all AWS accounts. In a multi-account, multi-environment architecture (e.g., Development, Staging, Production), we need a standardized way to generate resource names that are descriptive, unique, and clearly indicate their owner and environment.

## Decision

We will use a **Hierarchical Prefix and SHA-512 Hash** strategy for all resource names.

The naming strategy:
1.  **Prefix:** A base prefix is generated using `project_name-infrastructure_name-environment`. This makes it immediately obvious which project and environment a resource belongs to when viewing the AWS Console.
2.  **Short Hash:** To prevent naming collisions (e.g., when the prefix is long) and to ensure uniqueness for globally unique resources, an 8-character prefix hash is derived from the SHA-512 sum of the base prefix (`resource_prefix_hash`).
3.  **Truncation:** Resource names that have character limits (like IAM roles or RDS clusters) are carefully truncated or hashed to fit within AWS limits while maintaining as much human-readable context as possible.

## Consequences

**Positive:**
*   **Uniqueness:** Virtually eliminates the risk of naming collisions when deploying multiple environments to the same AWS account.
*   **Auditability:** Resources can be easily identified and grouped in the console or billing reports by their human-readable prefixes.
*   **Standardization:** Provides a consistent "look and feel" across the entire infrastructure, making it easier for engineers to find resources.

**Negative:**
*   **Verbosity:** Can result in very long resource names that may be difficult to read in some CLI outputs.
*   **Hashing Complexity:** Some resource names become less human-readable (e.g., `cf-a1b2c3d4-custom-stack`) compared to purely descriptive names.
*   **Re-naming difficulty:** If the `project_name` or `environment` variable changes, Terraform will attempt to recreate nearly every resource in the infrastructure because their names are derived from these inputs.