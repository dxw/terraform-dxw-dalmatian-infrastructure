# 10. Datadog as an Optional Experiment and Default Tooling

Date: 2024-10-10

## Status

Accepted

## Context

During the development of the Dalmatian platform, we conducted an experiment by running Datadog in parallel with our existing stack to evaluate it as a unified platform for metrics, logs, and Application Performance Monitoring (APM). Datadog provides a highly integrated and feature-rich observability experience. However, after the experimental period, its cost model at scale proved to be significantly higher than our current baseline requirements.

Our primary observability stack currently consists of:
*   **Papertrail:** For centralized log aggregation via Logspout.
*   **Amazon CloudWatch:** For infrastructure metrics and basic alerting.

## Decision

We have decided to keep the **Datadog Agent integration** in the codebase as an **optional, disabled-by-default feature**. While we do not use it for our core operations, retaining the code allows us to quickly satisfy requirements for clients who may already have a Datadog subscription or specifically request its feature set.

The core observability strategy remains:
1.  **Default Logging:** Standardized on Papertrail using a Logspout `DAEMON` service that runs on every ECS container instance.
2.  **Default Metrics:** Standardized on Amazon CloudWatch for all resource-level metrics (CPU, Memory, RDS throughput, etc.).
3.  **Optional Datadog:** The `enable_infrastructure_ecs_cluster_datadog_agent` flag remains available for experimental use or client-specific deployments.

## Consequences

**Positive:**
*   **Cost Control:** Avoids the significant recurring costs associated with Datadog for most standard platform deployments.
*   **Client Flexibility:** Retains the ability to quickly pivot to a premium observability stack if a client specifically requests it or is willing to fund the subscription.
*   **Proven Integration:** The code has been tested in parallel, ensuring that if it is enabled, it functions correctly with the rest of our ECS and network topology.

**Negative:**
*   **Technical Debt:** We are maintaining a block of code (ECR repositories, CodeBuild projects, IAM roles, and ECS Task Definitions) that is not used by the default platform configuration.
*   **Fragmentation:** Engineering teams need to be aware of the two different ways logs and metrics can be gathered, which increases the cognitive load when troubleshooting observability issues.
*   **Maintenance:** The Datadog agent and related Terraform code must still be kept up-to-date even when not in use.