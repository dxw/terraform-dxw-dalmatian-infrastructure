# 24. Standardized S3 Log Delivery and Retention

Date: 2023-11-17

## Status

Accepted

## Context

Infrastructure components (ALB, CloudFront, S3, VPC Flow Logs, Build Pipelines) generate extensive logs that are critical for operational visibility, security forensics, and compliance. Managing these logs individually across multiple S3 buckets can lead to inconsistent security, unmanaged costs, and difficulty in centralized analysis.

## Decision

We will standardize on a **Single "Infrastructure Logs" S3 Bucket** per regional environment.

The logging standards:
1.  **Consolidation:** All supported AWS services (ALB, CloudFront, S3 logging, etc.) are configured to deliver their logs into a single, central bucket (`s3-infrastructure-logs.tf`).
2.  **Path Isolation:** Each service uses a distinct prefix within the bucket (e.g., `alb/`, `cf/`, `vpc-flow-logs/`) to prevent file collisions and allow for easy categorization.
3.  **Security:** The bucket is private, versioned, and encrypted with the centralized Infrastructure KMS key. Access is controlled via a restrictive bucket policy that permits only specific AWS service principals to deliver logs.
4.  **Lifecycle Management:** All objects in the logging bucket are automatically transitioned to cheaper storage tiers (IA/Glacier) and eventually deleted based on a standardized `infrastructure_logging_bucket_retention` period.

## Consequences

**Positive:**
*   **Cost Management:** Unified lifecycle policies ensure that log storage costs are managed and that logs are automatically purged after the required retention period.
*   **Unified Analysis:** Provides a single "Source of Truth" for all infrastructure logs, making it easier to integrate with analytics tools like Amazon Athena.
*   **Security Oversight:** Simplifies the security posture by having a single location for auditing and access control of sensitive log data.

**Negative:**
*   **Complex Bucket Policy:** The central logging bucket's policy becomes very large and complex as it must accommodate delivery from many different AWS service principals and account-level IDs.
*   **Single Point of Failure:** If the logging bucket's policy or encryption is misconfigured, log delivery for the entire infrastructure could fail.
*   **Access Granularity:** It is more difficult to grant an engineer access to only "ALB logs" without also granting access to other logs in the same bucket.