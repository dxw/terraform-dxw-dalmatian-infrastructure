# 21. Custom Lambda Deployment Strategy

Date: 2024-03-27

## Status

Accepted

## Context

We need a way to deploy custom AWS Lambda functions for specialized infrastructure tasks (e.g., custom cleanup scripts, integrations) without the application code becoming a permanent part of the Terraform state. Managing large blocks of application code directly in Terraform can lead to slow plans, complex diffs, and tight coupling between infrastructure and code lifecycles.

## Decision

We will use a **"Plumbing and Placeholder"** strategy for custom Lambda deployments.

The implementation:
1.  **Plumbing:** Terraform provisions all the AWS-side infrastructure: IAM roles, CloudWatch Log Groups, VPC Security Groups, and the Lambda function resource itself.
2.  **Placeholder:** Terraform initially deploys a minimal "default" zip file (`lambdas/custom-lambda-default/function.py`) to the function.
3.  **Lifecycle Management:** Once the function is created, the `aws_s3_object` resource that holds the code has a `lifecycle { ignore_changes = [source, etag] }` block.
4.  **External Code Delivery:** Actual application code is pushed to the S3 bucket via an external CI/CD process. Terraform ensures the infrastructure exists, but it doesn't "fight" with the external process over the content of the zip file.

## Consequences

**Positive:**
*   **Decoupling:** Infrastructure changes and code changes can happen at different speeds.
*   **Performance:** Terraform plans remain fast because they aren't hashing large application artifacts.
*   **Flexibility:** Developers can update the Lambda code using standard AWS CLI or SDK tools without needing to run a full Terraform apply.

**Negative:**
*   **State Drift:** The code running in production is intentionally "drifted" from the code defined in Terraform.
*   **First-run Complexity:** The very first deployment requires the placeholder code to be valid for the configured handler and runtime, or the Lambda creation will fail.
*   **Orphaned Infrastructure:** If a Lambda is removed from Terraform, the code zip remains in the S3 bucket and must be cleaned up manually or via lifecycle policies.