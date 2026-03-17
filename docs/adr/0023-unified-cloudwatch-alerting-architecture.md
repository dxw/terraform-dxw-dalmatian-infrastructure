# 23. Unified CloudWatch Alerting Architecture

Date: 2024-06-25

## Status

Accepted

## Context

Infrastructure components (ECS, ASG, RDS, Lambda) generate critical metrics and events that require human intervention. We need a way to reliably alert on these failures (e.g., high CPU, pending tasks, scale-in drift) and route them to modern operational tools like Slack and Opsgenie.

## Decision

We will implement a **Unified Alerting Hub using Amazon SNS and CloudWatch Alarms**.

The alerting architecture:
1.  **Metric Collection:** Resources publish metrics directly to CloudWatch.
2.  **Alarm Configuration:** The module provisions standard CloudWatch Alarms for each feature area (e.g., `ecs-cluster-infrastructure-alert-asg-cpu.tf`).
3.  **Regional SNS Hubs:** Two central SNS topics are created in each regional infrastructure environment: one for **Slack Alerts** and one for **Opsgenie Alerts**.
4.  **Selective Routing:** Alerting configuration is controlled by feature-specific flags (e.g., `infrastructure_ecs_cluster_asg_cpu_alert_slack`).
5.  **Fan-out:** A single CloudWatch Alarm can trigger one or both SNS topics simultaneously, allowing for high-severity issues to be paged via Opsgenie while lower-priority issues only notify Slack.

## Consequences

**Positive:**
*   **Centralized Integration:** Third-party integrations (like a Slack Lambda or Opsgenie endpoint) only need to be configured once against the central SNS topic.
*   **Reduced Complexity:** New Alarms can easily hook into existing alerting paths without needing to reinvent the notification logic.
*   **Flexibility:** Different alert types (metric-based alarms vs. event-driven ECR scan results) use the same fan-out architecture.

**Negative:**
*   **SNS Limits:** If the volume of alerts becomes extremely high, SNS topic filtering and endpoint throughput must be monitored.
*   **Dependency on External Tools:** If Slack or Opsgenie is unavailable, the alerting chain will fail silently at the final delivery step.
*   **Configuration Management:** Managing which alerts go to which topic (Slack vs. Opsgenie) across many different Alarms requires careful parameterization of the Terraform module.