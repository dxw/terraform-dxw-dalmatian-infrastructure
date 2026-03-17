# 27. Bridging Terraform Gaps with External Data Scripts

Date: 2023-12-22

## Status

Accepted

## Context

The Terraform AWS Provider is comprehensive but does not support every possible AWS API operation or dynamic value generation. Some tasks—such as generating a temporary pre-signed S3 URL for a CloudFormation template or fetching a specialized AWS service setting—require executing logic that is better handled by the AWS CLI or an SDK.

## Decision

We will use the **`external` data source** and **shell scripts** to perform specialized operations that are not natively supported by Terraform.

The implementation:
1.  Specialized scripts are stored in `external-data-scripts/` (e.g., `s3-object-presign.sh`, `get-ssm-service-setting.sh`).
2.  Terraform invokes these scripts using the `external` data source, passing parameters via standard input and receiving a JSON object via standard output.
3.  The output values are then used directly in other Terraform resources (e.g., passing a pre-signed URL to `aws_cloudformation_stack`).

## Consequences

**Positive:**
*   **Gap Coverage:** Allows the module to perform critical tasks that would otherwise require manual intervention.
*   **Automation:** Keeps the entire infrastructure lifecycle within a single `terraform apply` command.
*   **Native Tooling:** Leverages the power of the AWS CLI, which often receives updates and new features faster than the Terraform provider.

**Negative:**
*   **Environment Dependency:** Requires the machine running Terraform (local or CI/CD) to have a bash environment and the AWS CLI installed.
*   **Security Risk:** Scripts executed via `external` have the same permissions as the Terraform execution role. This must be carefully audited to prevent command injection.
*   **Platform Portability:** Bash scripts are not natively portable to Windows environments without specialized shells like Git Bash or WSL.
*   **Performance:** External scripts are slower than native provider calls because they require spawning a new process and potentially multiple network round-trips via the AWS CLI.