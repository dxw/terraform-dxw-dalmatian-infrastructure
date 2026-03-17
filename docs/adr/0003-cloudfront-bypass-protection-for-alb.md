# 3. CloudFront Bypass Protection for ALB

Date: 2023-11-01

## Status

Accepted

## Context

Many of our services are public-facing and utilize Amazon CloudFront as a Content Delivery Network (CDN) to cache static assets, terminate TLS, and integrate AWS WAF at the edge. These CloudFront distributions route dynamic traffic back to Application Load Balancers (ALBs) running in our public or private subnets. 

A common vulnerability in this architecture is that malicious actors can discover the DNS name or IP address of the ALB and send requests directly to it, effectively bypassing CloudFront. This circumvents any caching rules, geographic restrictions, and most importantly, the Web Application Firewall (WAF).

## Decision

We will implement **CloudFront Bypass Protection** using secret header injection.

When `cloudfront_bypass_protection_enabled` is set:
1. Terraform provisions a randomly generated secret password.
2. CloudFront is configured to inject a custom HTTP header (e.g., `X-Custom-Header`) containing this secret on every origin request forwarded to the ALB.
3. The ALB is configured with a default rule that denies traffic (returns a 403 or drops) unless the `X-Custom-Header` exactly matches the shared secret.

## Consequences

**Positive:**
* **Enhanced Security:** Ensures all traffic reaching the application has successfully traversed CloudFront and been inspected by the WAF.
* **No IP Allowlisting:** Removes the need to maintain cumbersome and frequently changing security group rules that attempt to allowlist CloudFront edge IP ranges.

**Negative:**
* **Complexity with Global Accelerator:** If AWS Global Accelerator is used simultaneously with the ALB, exceptions must be explicitly managed via `cloudfront_bypass_protection_excluded_domains` so legitimate non-CloudFront traffic isn't dropped.