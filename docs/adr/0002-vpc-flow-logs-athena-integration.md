# 2. Log Analytics via Athena and Glue Integration

Date: 2023-11-17

## Status

Accepted

## Context

Analyzing infrastructure logs (VPC Flow Logs, CloudFront access logs) is critical for security audits, debugging connectivity issues, and understanding traffic patterns. Publishing logs to CloudWatch is easier for ad-hoc searching but becomes prohibitively expensive at scale and lacks the complex relational querying capabilities needed for deep analysis. Storing them in S3 is cost-effective but raw log files are difficult to query without significant processing.

## Decision

We will allow infrastructure logs (VPC Flow Logs and CloudFront Access Logs) to be written directly to a centralized **S3 Bucket** and automatically provision **Amazon Athena Workgroups and AWS Glue Data Catalogs** alongside them.

The implementation:
*   Standardizes schemas for both VPC Flow Logs and CloudFront logs via Glue Tables.
*   Enables SQL-based querying of log data directly from the AWS Console using Athena.
*   Uses partition projection (year/month/day/hour) to optimize query performance and reduce scanning costs.

## Consequences

**Positive:**
*   **Cost Savings:** Storing massive volumes of flow and access logs in S3 is significantly cheaper than ingesting and storing them in CloudWatch Logs.
*   **Powerful Querying:** Amazon Athena allows us to write standard SQL queries against the raw logs, making it trivial to aggregate traffic, identify top talkers, or audit security events over long timeframes.
*   **Unified Analytics:** Provides a consistent interface for analyzing different types of infrastructure logs.

**Negative:**
*   **Delayed Insights:** S3 object delivery and Athena querying inherently have a higher latency (usually minutes) compared to near-real-time streaming in CloudWatch Logs.
*   **Complexity:** Requires deploying and maintaining multiple Glue Table schema configurations and Athena configurations.