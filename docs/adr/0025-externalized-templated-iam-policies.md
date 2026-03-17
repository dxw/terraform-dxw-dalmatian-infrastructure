# 25. Externalized Templated IAM Policies

Date: 2023-11-08

## Status

Accepted

## Context

AWS Identity and Access Management (IAM) policies can be extremely verbose and difficult to read when embedded directly within Terraform resources using inline HCL or long heredoc strings. Furthermore, many policies share common patterns (e.g., "allow logging to CloudWatch") that are repeated across multiple roles and services.

## Decision

We will maintain a dedicated **`policies/` directory** containing **`.json.tpl` files** for all IAM and resource-based policies.

The implementation:
1.  Policies are written in standard JSON format with Terraform interpolation placeholders (e.g., `${region}`, `${account_id}`).
2.  Terraform uses the `templatefile()` function to load and populate these policies at runtime.
3.  Common policy fragments (e.g., standard assume-role policies) are stored in subdirectories like `policies/assume-roles/` for easy reuse.

## Consequences

**Positive:**
*   **Readability:** JSON files provide a familiar and clean format for security engineers to audit.
*   **Reusability:** The same template can be reused across multiple services by passing different variables to the `templatefile()` function.
*   **Validation:** External JSON files can be easily linted or validated using standard JSON tools outside of the Terraform context.

**Negative:**
*   **Indirection:** Developers must switch between HCL files and JSON files to understand the full configuration of a resource.
*   **Runtime Errors:** Errors in the template (e.g., missing variables) are only caught during the Terraform `plan` or `apply` phase, rather than during static HCL parsing.
*   **Variable Management:** Requires carefully managing the map of variables passed to each `templatefile` call to ensure all placeholders are correctly populated.