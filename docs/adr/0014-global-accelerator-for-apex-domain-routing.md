# 14. Global Accelerator for Apex Domain Routing

Date: 2024-03-05

## Status

Accepted

## Context

AWS Application Load Balancers (ALBs) do not provide a fixed, static IP address. Instead, they provide a DNS name. This makes it difficult to route "apex" domains (e.g., `example.com` without a `www.` prefix) to an ALB, as the DNS standard for an apex record (A record) requires an IP address, not another DNS name (CNAME). While Amazon Route 53 supports ALIAS records for this purpose, these only work within the Route 53 ecosystem.

Furthermore, applications that require globally low-latency access or need to traverse the AWS network backbone instead of the public Internet can benefit from a more consistent entry point.

## Decision

We will use **AWS Global Accelerator (GA)** for routing apex domains and providing a globally optimized network entry point for our ECS application services.

When `infrastructure_ecs_cluster_services_alb_enable_global_accelerator` is enabled:
1.  Terraform provisions an AWS Global Accelerator accelerator with two static Anycast IP addresses.
2.  Global Accelerator is configured to route traffic on ports 80 and 443 to the regional Application Load Balancer (ALB).
3.  DNS A records (including apex domains) are then pointed towards the two static IPs provided by Global Accelerator.

## Consequences

**Positive:**
*   **Apex Domain Support:** Provides a consistent, standard way to route root domains to our services using traditional A records if Route 53 ALIAS records aren't suitable or if the client's DNS is managed elsewhere.
*   **Global Performance:** Traffic enters the AWS network at the edge location closest to the user, traversing the AWS backbone to reach the ALB, reducing latency and increasing network stability.
*   **High Availability:** Global Accelerator can automatically reroute traffic around healthy regions (though currently, our module focuses on single-region deployments).

**Negative:**
*   **Additional Cost:** Global Accelerator incurs a fixed hourly charge plus a data transfer charge based on the destination region and amount of traffic.
*   **Bypass Protection Conflict:** If using CloudFront Bypass Protection (ADR 0003), traffic arriving via Global Accelerator will be dropped by the ALB unless the relevant domains are explicitly added to `cloudfront_bypass_protection_excluded_domains`.
*   **IP Address Staticity:** While having static IPs is usually a benefit, it can become a target for DDoS attacks if not properly shielded by WAF or other edge protections.