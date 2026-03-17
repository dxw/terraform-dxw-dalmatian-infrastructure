# 5. Use SSM Session Manager for Bastion Host

Date: 2024-09-09

## Status

Accepted

## Context

Traditionally, bastion hosts (jump boxes) are used to provide access to resources in private subnets. These usually require SSH access, which means opening port 22 in security groups and managing SSH keys for all users. Maintaining SSH keys is an administrative burden, and exposing port 22, even to limited IP ranges, increases the attack surface of the infrastructure.

## Decision

We will use **AWS Systems Manager (SSM) Session Manager** for accessing our bastion hosts, rather than traditional SSH.

The bastion host:
*   Will not have any inbound rules in its security group (effectively "stealth" mode).
*   Does not require any SSH keys to be provisioned or managed.
*   Uses an IAM role with the `AmazonSSMManagedInstanceCore` policy to allow the SSM agent to communicate with the AWS service.
*   Is accessed via the AWS CLI or Console using `aws ssm start-session`.

## Consequences

**Positive:**
*   **Security:** No open inbound ports (including 22). Access is controlled entirely through IAM.
*   **Auditability:** Every session and command can be logged to CloudWatch or S3 through SSM features.
*   **Operational Simplicity:** No need to manage, rotate, or revoke SSH keys for team members.
*   **Cost:** Uses standard t3.micro instances without additional third-party access software.

**Negative:**
*   **Tooling Dependency:** Requires users to have the AWS CLI and the Session Manager plugin installed locally.
*   **Network Dependency:** The instance must have outbound HTTPS (port 443) access to communicate with the SSM service endpoints.