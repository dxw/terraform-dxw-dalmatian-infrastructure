# 18. Ephemeral VPC File Transfer Mechanism

Date: 2024-05-30

## Status

Accepted

## Context

Resources running in private subnets (e.g., EC2 Bastion, ECS tasks) frequently need a way to upload or download files (e.g., database dumps, configuration files, logs). However, granting these resources direct internet access via a NAT Gateway is not always desirable for all accounts, and setting up complex VPC Endpoints for every possible AWS service can be cumbersome.

## Decision

We will implement a **centralized VPC S3 Transfer mechanism** using **S3 and AWS Systems Manager (SSM) Documents**.

The implementation:
1.  Creates an optional S3 bucket (`vpc-infrastructure-s3-transfer.tf`) for file transfers, restricted by VPC ID.
2.  Provides custom SSM Documents (`ssm-documents/s3-download.json.tpl` and `ssm-documents/s3-upload.json.tpl`) that can be executed against any instance in the VPC.
3.  Automates the permissions for instances to securely read and write to this specific transfer bucket.

## Consequences

**Positive:**
*   **Security:** File transfers are restricted at the network (VPC ID) and IAM level. No open ingress/egress is required for the transfers.
*   **Ease of Use:** Provides a standard, documented way for engineers to move data in and out of the VPC using the AWS CLI or Console.
*   **Auditability:** Every execution of the SSM Documents is logged and can be audited in the Systems Manager history.

**Negative:**
*   **Resource Overhead:** Requires deploying an additional S3 bucket and several SSM documents.
*   **Manual Steps:** While the mechanism is automated, it still requires an engineer to trigger the document execution unless further automation is built on top of it.
*   **Dependency on SSM:** Only works for instances and containers that have the SSM agent installed and the necessary IAM permissions to communicate with the SSM service.