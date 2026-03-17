# 30. Tiered Storage Lifecycle Policies for Cost Management

Date: 2024-03-06

## Status

Accepted

## Context

Infrastructure components generate large volumes of data that decrease in value over time (e.g., historical logs, CI/CD artifacts, database backups). Storing all of this data indefinitely in high-performance S3 Standard storage is not cost-effective and can lead to ballooning AWS bills.

## Decision

We will implement **standardized S3 Lifecycle Policies** for all data-heavy S3 buckets provisioned by the module.

The implementation:
1.  **Artifacts:** CI/CD artifact buckets automatically expire objects after a short period (e.g., 30 days) as older builds are rarely needed.
2.  **Logs:** The "Infrastructure Logs" bucket uses a tiered approach: transition to Standard-IA (Infrequent Access) after 30 days, Glacier after 90 days, and permanent deletion after the configured retention period.
3.  **Backups:** RDS S3 backups are transitioned to colder storage and eventually expired to balance disaster recovery needs with storage costs.
4.  **Empty Filters:** Policies are applied globally to the bucket using an empty filter (`filter {}`) to ensure all objects are covered by default.

## Consequences

**Positive:**
*   **Cost Optimization:** Dramatically reduces the long-term cost of storing logs and backups by moving them to cheaper storage classes automatically.
*   **Compliance:** Ensures that data is not kept longer than required by organizational policies, aiding in data privacy compliance (e.g., GDPR).
*   **Operational Efficiency:** Data management is completely automated and doesn't require manual cleanup scripts.

**Negative:**
*   **Retrieval Latency:** Accessing older logs or backups moved to Glacier requires a "thaw" period (minutes to hours) and potential retrieval fees.
*   **Complexity:** Managing overlapping lifecycle rules across many buckets requires careful documentation to avoid accidental data loss.
*   **Hidden Costs:** AWS charges for the transition operations themselves, which can be significant if the bucket contains millions of very small objects.