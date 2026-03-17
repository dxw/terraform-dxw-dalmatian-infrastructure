# 17. CloudFormation "Escape Hatch" Integration

Date: 2024-03-21

## Status

Accepted

## Context

Terraform is our primary tool for infrastructure management. However, some AWS services or specialized configurations are better handled via AWS CloudFormation. This may occur because:
*   The Terraform provider does not yet support a specific feature.
*   A CloudFormation resource has more sophisticated lifecycle management for a particular use case.
*   The team has existing, well-tested CloudFormation templates they wish to reuse.

## Decision

We will provide a **native integration for CloudFormation Stacks** to serve as an "escape hatch" within the Terraform module.

The implementation:
1.  Creates an optional S3 bucket specifically to store CloudFormation templates (`cloudformation-custom-stack-s3-template-store.tf`).
2.  Provides a mechanism to deploy `custom_cloudformation_stacks` from either an inline string (`template_body`) or from a template stored in S3 (`s3_template_store_key`).
3.  Uses an external data script (`external-data-scripts/s3-object-presign.sh`) to generate a pre-signed S3 URL for the template, allowing CloudFormation to securely fetch the template from the private S3 bucket without making the bucket public.

## Consequences

**Positive:**
*   **Maximum Flexibility:** Provides a structured way to extend the infrastructure when Terraform hits its limits.
*   **Security:** Keeps templates stored securely in a private, encrypted S3 bucket while still allowing CloudFormation to access them via temporary pre-signed URLs.
*   **Declarative Consistency:** Integrates CloudFormation resources directly into the Terraform graph, allowing for consistent ordering and lifecycle management (e.g., dependency on a VPC).

**Negative:**
*   **State Fragmentation:** Resources managed by CloudFormation are not directly visible in the Terraform state file, making it harder to track all changes via `terraform plan`.
*   **Scripting Dependency:** The use of an external data script for pre-signing requires a bash environment with the AWS CLI available on the machine running Terraform.
*   **Troubleshooting:** Errors in the CloudFormation stack creation are surfaced through the CloudFormation Console, not directly through Terraform's output, requiring more steps to debug.