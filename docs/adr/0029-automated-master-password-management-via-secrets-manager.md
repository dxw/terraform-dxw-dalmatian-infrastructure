# 29. Automated Master Password Management via Secrets Manager

Date: 2025-04-04

## Status

Accepted

## Context

Managing the master password for an RDS database or Aurora cluster is a critical security task. Traditionally, passwords were either hardcoded in variables (insecure), prompted for during execution (not automated), or generated and stored in the Terraform state (visible in plain text in the state file). We need a method that is both highly secure and fully automated for CI/CD environments.

## Decision

We will use the **AWS native secret management integration** for RDS and Aurora.

The implementation:
1.  The `aws_rds_cluster` or `aws_db_instance` resource is configured with `manage_master_user_password = true`.
2.  AWS automatically generates a strong, random password for the master user upon resource creation.
3.  The password is automatically "escrowed" into a new AWS Secrets Manager secret.
4.  **Automated Rotation:** AWS is configured to automatically rotate this master password every 7 days, significantly improving the security posture without manual intervention.
5.  The secret is encrypted using either the centralized Infrastructure KMS key or a dedicated RDS KMS key.
6.  Applications and engineers access the password by querying the secret in Secrets Manager rather than passing it via Terraform variables.

## Consequences

**Positive:**
*   **Security Hygiene:** Passwords are never stored in plain text in Terraform source code or state files.
*   **Automation:** Eliminates the need for manual password generation or injection during the build process.
*   **Lifecycle Management:** AWS can automatically rotate the master password in Secrets Manager without needing to update Terraform or re-apply the infrastructure.

**Negative:**
*   **Indirect Access:** Engineers must have IAM permissions to read from Secrets Manager to retrieve the database credentials for debugging.
*   **Cost:** Each secret in AWS Secrets Manager incurs a small monthly cost ($0.40 per secret).
*   **Cleanup:** If the RDS instance is deleted, the escrowed secret in Secrets Manager may need to be manually scheduled for deletion.