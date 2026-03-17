# 8. Blue/Green Deployment Strategy with CodeDeploy for ECS

Date: 2024-02-29

## Status

Accepted

## Context

Deploying updates to mission-critical services requires a strategy that minimizes downtime and provides an easy rollback mechanism. Standard ECS "rolling" deployments simply replace tasks one-by-one, which can lead to transient errors if a bad version is deployed. A Blue/Green deployment, on the other hand, provisions a separate set of tasks (the "Green" group) and only shifts traffic once they are healthy.

## Decision

We will use **AWS CodeDeploy** for Blue/Green deployments on Amazon ECS when `deployment_type` is set to `blue-green`.

The strategy involves:
*   Two target groups per service (Blue and Green).
*   CodeDeploy managing the traffic shift between target groups on the ALB.
*   Automated rollback triggered if any CloudWatch alarms go off or the health checks fail.
*   A `terraform_data` resource that automatically generates an `AppSpec` JSON file and triggers the CodeDeploy deployment upon task definition changes.

## Consequences

**Positive:**
*   **Safety:** Zero downtime deployments as the Green version is fully warmed and healthy before traffic shifting begins.
*   **Instant Rollback:** Traffic can be shifted back to the original Blue version instantly if a failure is detected during the cutover window.
*   **Verification Window:** Ability to hold traffic on the Green version for manual testing before performing the final cutover.

**Negative:**
*   **Increased Resource Usage:** During the deployment, twice the number of tasks are running (both Blue and Green), which may require additional EC2 capacity.
*   **Complexity:** Requires managing CodeDeploy applications, deployment groups, two sets of target groups, and custom IAM roles.
*   **Infrastructure Delay:** Blue/Green deployments take longer than rolling updates because of the health check and waiting windows.
*   **ALB Dependency:** Blue/Green deployments for ECS are only supported when services are behind an Application Load Balancer.