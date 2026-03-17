# 1. Use EC2 for ECS instead of Fargate

Date: 2023-12-19

## Status

Accepted

## Context

When orchestrating containers with Amazon Elastic Container Service (ECS), we have the choice between using AWS Fargate (serverless compute) or managing our own EC2 instances using an Auto Scaling Group (ASG). Fargate offloads instance management, patching, and scaling of the underlying compute nodes, whereas EC2 requires us to manage the capacity, AMIs, and scaling behavior of the underlying infrastructure. 

However, running workloads on EC2 provides access to more granular host-level capabilities and caching which is beneficial for the kinds of applications hosted on the Dalmatian platform.

## Decision

We will use **EC2-backed ECS clusters** as our primary compute strategy rather than AWS Fargate. 

To mitigate the administrative overhead of using EC2, we will automate instance management:
* Implement an Auto Scaling Group (ASG) scaled by CPU and time-based metrics.
* Use a customized draining lambda function to safely drain tasks before instance termination.
* **Automated AMI Updates:** Use a custom **Instance Refresh Lambda** that automatically triggers a rolling update of the ASG instances whenever the underlying AMI or Launch Template is updated, ensuring the cluster stays patched without manual intervention.

## Consequences

**Positive:**
* **Cost Efficiency:** EC2 instances are generally cheaper for consistent workloads compared to Fargate.
* **Host-level Access:** We can deploy DaemonSets like Datadog Agent and Logspout directly to the host for comprehensive log aggregation and infrastructure monitoring.
* **Caching and EFS:** Better control over persistent volume mounts (like EFS) and host-level Docker caching.

**Negative:**
* **Operational Overhead:** We must maintain custom Lambdas to handle safe instance draining and automated instance refreshes to keep AMIs patched.
* **Capacity Management:** Need to meticulously tune ASG scaling policies to avoid under-provisioning or over-provisioning compute capacity.