# 6. Centralized Infrastructure KMS Key

Date: 2023-11-08

## Status

Accepted

## Context

AWS Key Management Service (KMS) is used to encrypt data at rest across many AWS services (S3, RDS, EBS, CloudWatch Logs, etc.). Managing a separate KMS key for every service or every application can become complex and difficult to audit. Furthermore, many AWS services require specific, granular policy statements to allow them to use a KMS key (e.g., CloudWatch Logs, CloudFront, etc.).

## Decision

We will implement a **centralized Infrastructure KMS Key** to be used globally across all resources by default.

This key:
*   Consolidates all necessary policy statements (CloudWatch Logs, CloudFront OAC, etc.) into one managed policy (`kms-infrastructure.tf`).
*   Is used by default for S3 buckets, RDS instances, and ECS tasks unless a dedicated key is explicitly requested for isolation.
*   Simplifies access control by centralizing the `kms:Decrypt` and `kms:Encrypt` grants in a single location.
*   **Supports custom extensions:** Provides an `infrastructure_kms_key_policy_statements` variable that allows engineers to inject additional, ad-hoc policy statements into the centralized key without modifying the module's core logic.

## Consequences

**Positive:**
*   **Ease of Management:** Redundant KMS policy boilerplate is eliminated as most services share common encryption needs.
*   **Lower Costs:** Reduced monthly fixed costs by having fewer KMS keys in the account ($1 per key/month).
*   **Standardization:** Ensures that all resources created by the module are encrypted by default using a consistent standard.

**Negative:**
*   **Single Point of Failure:** If the centralized key's policy is misconfigured, it could impact encryption/decryption across the entire infrastructure.
*   **Less Granularity:** Harder to implement strict isolation where one application cannot read the encrypted data of another at the KMS layer without creating custom roles and policy logic.
*   **Complexity of Policy:** The central KMS key policy becomes very large as it needs to include allow-statements for many different service principals and IAM roles.