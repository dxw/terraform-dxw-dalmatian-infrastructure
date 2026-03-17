# 11. S3 Private-by-Default and CloudFront OAC

Date: 2024-03-06

## Status

Accepted

## Context

Hosting static assets and media files through Amazon S3 is a core requirement for our applications. However, exposing S3 buckets directly to the public Internet via bucket policies or ACLs is a frequent source of security misconfigurations. 

Furthermore, we often want to leverage Amazon CloudFront for content delivery, caching, and integrating with AWS WAF. Historically, this required configuring S3 buckets with Origin Access Identities (OAI), which had several limitations, particularly around AWS KMS encryption support.

## Decision

We will standardize on **S3 Private-by-Default and CloudFront Origin Access Control (OAC)** for all static content delivery.

Under this architecture:
1.  All custom S3 buckets are created with `Block Public Access` enabled and ACLs disabled.
2.  Buckets are encrypted at rest using the centralized Infrastructure KMS key (or a dedicated key).
3.  Direct public access to the bucket is prohibited.
4.  CloudFront distributions are configured with **Origin Access Control (OAC)**, which allows CloudFront to securely sign requests to the private S3 bucket.
5.  A bucket policy is automatically provisioned to allow only the specific CloudFront distribution's service principal (`cloudfront.amazonaws.com`) to read objects from the bucket.

## Consequences

**Positive:**
*   **Enhanced Security:** Buckets are completely private. There is no risk of accidental data exposure through broad bucket policies or public ACLs.
*   **KMS Encryption Support:** OAC supports server-side encryption with AWS KMS, unlike the older OAI method.
*   **Simplified Access Control:** All traffic is forced through CloudFront, allowing us to consistently apply WAF rules, geolocation restrictions, and custom headers across all assets.

**Negative:**
*   **Cost:** CloudFront delivery is generally more expensive than raw S3 data transfer for very small workloads.
*   **Complexity:** Requires managing additional CloudFront distributions, Origin Access Controls, and specific S3 bucket policies for every "public" asset bucket.
*   **Latency:** There is a slight initial overhead for the CloudFront edge nodes to fetch the content from the origin S3 bucket (mitigated by caching).