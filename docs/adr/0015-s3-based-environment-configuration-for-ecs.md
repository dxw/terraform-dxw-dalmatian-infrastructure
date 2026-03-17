# 15. S3-based Environment Configuration for ECS

Date: 2024-01-22

## Status

Accepted

## Context

Managing environment variables for containerized applications can become cumbersome when dealing with a large number of variables or different environments. While AWS Secrets Manager and SSM Parameter Store are excellent for individual secrets, they are not always the most efficient way to manage large collections of non-sensitive configuration data or bulk environment files.

## Decision

We will use a **dedicated, encrypted S3 bucket** to store bulk environment files (`.env` style) for ECS services.

The implementation:
1.  Creates a central S3 bucket specifically for environment files (`ecs-cluster-infrastructure-service-s3-environment-files.tf`).
2.  The bucket is private, versioned, and encrypted with the centralized Infrastructure KMS key.
3.  ECS task definitions are configured to pull environment files directly from this bucket at runtime using the `environmentFiles` parameter in the container definition.
4.  The ECS Task Execution Role is granted read-only access to specific files in this bucket.

## Consequences

**Positive:**
*   **Operational Efficiency:** Easier to manage hundreds of configuration variables in a single file compared to hundreds of individual SSM parameters.
*   **Version Control:** Leverages S3 versioning to provide a history of configuration changes.
*   **Developer Experience:** Familiar `.env` file workflow that can be easily integrated into local development and CI/CD pipelines.

**Negative:**
*   **Secret Exposure Risk:** If sensitive secrets are accidentally committed to the environment file instead of referenced via Secrets Manager, they are stored in plain text (though the bucket itself is encrypted at rest).
*   **Cold Start Latency:** Slight overhead for the ECS agent to fetch the environment file from S3 before starting the container.
*   **Visibility:** Variables stored in S3 files are not directly visible or editable in the AWS ECS Console UI, unlike standard environment variables.