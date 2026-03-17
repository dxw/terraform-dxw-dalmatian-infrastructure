# 16. Cross-Account DNS Delegation Pattern

Date: 2023-12-06

## Status

Accepted

## Context

We often manage infrastructure in multiple AWS accounts (e.g., Development, Staging, Production). However, the "root" domain (e.g., `dxw.net`) is typically managed in a single, highly secure administrative AWS account. To provision subdomains for each regional infrastructure environment (e.g., `staging.dalmatian.dxw.net`), we need a way to automate the delegation of Name Servers from the root account to the regional infrastructure account.

## Decision

We will use a **cross-account provider pattern** to automate DNS delegation during the infrastructure build.

The implementation:
1.  Requires a dedicated Terraform provider (`aws.awsroute53root`) that is configured with credentials for the root domain's AWS account.
2.  The module creates a new Route 53 Hosted Zone in the local (regional) account.
3.  The module then uses the `aws.awsroute53root` provider to create an `NS` (Name Server) record in the root account's Hosted Zone, pointing to the four Name Servers of the new regional Hosted Zone.

## Consequences

**Positive:**
*   **Fully Automated Setup:** No manual intervention is needed to delegate a new subdomain to a regional account.
*   **Infrastructure-as-Code Integrity:** The entire DNS hierarchy for the infrastructure is managed within the same Terraform execution, ensuring consistency.
*   **Clean Subdomain Separation:** Each regional infrastructure environment has its own Hosted Zone, allowing for independent record management and delegated DNS administration.

**Negative:**
*   **Credential Complexity:** Requires the Terraform execution environment to have cross-account IAM permissions or credentials for both the regional account and the root DNS account.
*   **Security Risk:** The CI/CD system running Terraform now has write access to the root DNS account, which is a highly sensitive resource. This must be carefully managed with scoped IAM policies.
*   **Provider Dependency:** Terraform must be configured with both the standard `aws` provider and the `aws.awsroute53root` alias.