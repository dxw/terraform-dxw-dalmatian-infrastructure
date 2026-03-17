# 20. Serverless-First Database and Cache Scaling

Date: 2024-02-15

## Status

Accepted

## Context

Managing relational databases and in-memory caches requires balancing performance, availability, and cost. Traditionally, this involves provisioning fixed-size instances (e.g., `db.t3.medium`). However, these fixed instances are often over-provisioned during idle periods and can become a bottleneck during peak traffic, requiring manual intervention to upscale.

## Decision

We will prioritize **AWS Aurora Serverless v2 and ElastiCache Serverless** as the default scaling strategies for database and cache resources within the Dalmatian platform.

The strategy involves:
1.  **RDS:** Using Aurora Serverless v2 by default, which allows the database to automatically scale its capacity (ACUs) up and down based on real-time application demand.
2.  **ElastiCache:** Using the Serverless offering for Redis, which removes the need to manage clusters, shards, or nodes.
3.  **Provisioned Fallback:** Retaining support for traditional provisioned instances (RDS and ElastiCache clusters) for legacy workloads or cases where the performance profile of serverless is not appropriate.

## Consequences

**Positive:**
*   **Operational Simplicity:** Removes the administrative overhead of managing instance sizes, read replicas, and shards for scaling.
*   **Cost Optimization:** Pay only for the capacity consumed by the application, which is highly efficient for workloads with variable traffic patterns.
*   **Rapid Scaling:** Serverless offerings can scale capacity in seconds, providing a much more responsive experience during traffic spikes.

**Negative:**
*   **Cold Starts:** In some very low-traffic scenarios, there may be a slight latency when the database or cache scales up from its minimum capacity.
*   **Cost Predictability:** Serverless costs are dynamic and based on usage, making it harder to predict a fixed monthly spend compared to provisioned instances.
*   **Minimum Capacity Cost:** Both Aurora Serverless v2 and ElastiCache Serverless have a minimum hourly charge (0.5 ACU and a base storage/data transfer fee) which might be higher than a very small fixed instance (e.g., `t4g.micro`).
*   **Region Availability:** Some serverless offerings may not be available in all AWS regions at the same time as provisioned instances.