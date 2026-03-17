# 9. Use Fargate for Ephemeral Utilities Cluster

Date: 2025-04-15

## Status

Accepted

## Context

Our main application workloads run on EC2-backed ECS clusters (see ADR 0001) for cost efficiency and specialized host-level monitoring. However, certain infrastructure operations (like database backups, one-off scripts, or ephemeral tasks) don't require high-performance host-level integration. Running these on the main cluster can lead to resource contention and complicates the scaling logic of the primary ASG. Initially scoped only for RDS tooling, the need for a general-purpose utilities compute layer became apparent.

## Decision

We will provision a secondary **"Utilities" ECS Cluster** specifically designed to run tasks using the **AWS Fargate** (serverless) launch type.

This cluster:
*   Does not manage any EC2 instances.
*   Is used by components like `RDS S3 Backups` and other ad-hoc maintenance utilities.
*   Provides a clean separation between long-running production application services and short-lived infrastructure tasks.
*   Uses a generalized "Utilities" Docker image that can be extended with various entrypoints for different operational tasks.

## Consequences

**Positive:**
*   **Isolation:** Infrastructure tasks (like backups) cannot impact the resource availability of production application services.
*   **Ease of Deployment:** No need to manage capacity for these ad-hoc tasks. Fargate scales automatically to meet the demand.
*   **Versatility:** The cluster can be used for any ephemeral task that doesn't require specialized EC2 host access.
*   **Security:** These tasks run on their own isolated compute nodes, reducing the blast radius of any security incidents within utility scripts.

**Negative:**
*   **Cost:** Standard Fargate can be slightly more expensive for long-running tasks compared to EC2, though this is mitigated by the ephemeral nature of utility tasks.
*   **Startup Latency:** Fargate tasks typically have a slightly longer startup time compared to tasks starting on an already-running EC2 host.