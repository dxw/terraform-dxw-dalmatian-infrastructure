# 7. Automated Resource Tagging via Local-Exec

Date: 2025-03-07

## Status

Accepted

## Context

Resource tagging is essential for cost allocation, resource grouping, and compliance in AWS. While Terraform supports `default_tags` at the provider level, not all AWS resources support this mechanism natively, especially some older resources or certain resource-level configurations. Some resources may not even support tags via Terraform but can be tagged through the AWS CLI or SDK.

## Decision

We will use a **`local-exec` provisioner** to automatically tag resources by their Amazon Resource Name (ARN) if they don't natively support robust Terraform tagging or if we want to ensure mandatory tags are applied outside of Terraform's state-driven logic.

The implementation:
*   Uses a `terraform_data` resource as a trigger for the tagging script (`tag-resources.tf`).
*   Executes a custom bash script (`local-exec-scripts/tag-resources.sh`) that takes a list of ARNs and a JSON blob of tags.
*   Calls the AWS CLI `tag-resource` commands to apply the specified key-value pairs.

## Consequences

**Positive:**
*   **Completeness:** Enables tagging of resources that the Terraform AWS provider might not support tagging for.
*   **Enforcement:** Guarantees that mandatory tags are applied even if they are missing from individual resource blocks.

**Negative:**
*   **State Drift:** Tags applied via `local-exec` are not managed in the Terraform state file. If these tags are deleted manually in the AWS Console, Terraform will not detect the change and will only re-apply them if the `terraform_data` trigger is activated.
*   **Execution Dependency:** Requires the local environment (or CI/CD runner) to have the AWS CLI installed and configured.
*   **Debugging Difficulty:** Errors in the `local-exec` script are harder to troubleshoot as they occur during the Terraform `apply` phase outside of Terraform's standard provider-level logging.
*   **Apply Latency:** Adding a `custom_resource_tags_delay` (to allow resources to finish provisioning before tagging them) increases the total time to apply changes.