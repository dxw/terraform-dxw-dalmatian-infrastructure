# 26. Multi-Region ACM for Global Services (CloudFront)

Date: 2024-02-06

## Status

Accepted

## Context

AWS Certificate Manager (ACM) certificates are regional resources. However, AWS CloudFront is a global service that requires certificates to be provisioned in the **`us-east-1` (N. Virginia)** region to be associated with a distribution, regardless of where the rest of the infrastructure is located. 

Our module typically operates in a specific primary region (e.g., `eu-west-2`). If a service enables CloudFront, we must ensure a matching certificate exists in both the primary region (for the ALB) and `us-east-1` (for CloudFront).

## Decision

We will use a **multi-region provider pattern** to automatically provision certificates in `us-east-1` for global services.

The implementation:
1.  Requires a dedicated Terraform provider (`aws.useast1`) to be configured in the root module.
2.  The module creates two identical `aws_acm_certificate` resources for the infrastructure wildcard domain: one using the default regional provider and one using the `aws.useast1` provider (`certificates-infrastructure.tf`).
3.  The module handles DNS validation for both certificates simultaneously using the regional Route 53 Hosted Zone.

## Consequences

**Positive:**
*   **Seamless Global Delivery:** Allows for automated, zero-touch provisioning of HTTPS for both regional ALBs and global CloudFront distributions.
*   **Infrastructure-as-Code Integrity:** Eliminates the manual step of switching regions in the AWS Console to create certificates.

**Negative:**
*   **Provider Complexity:** Requires every project using this module to explicitly configure and pass two providers (`aws` and `aws.useast1`).
*   **Resource Duplication:** We are paying for (and managing) two certificates for the same domain name, which increases the number of resources in the Terraform state.
*   **Increased Validation Time:** DNS validation must complete for two separate certificates before the stack is considered fully provisioned.