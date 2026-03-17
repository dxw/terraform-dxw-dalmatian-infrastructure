# 19. Multi-AZ Subnet and Route Table Topology

Date: 2023-11-21

## Status

Accepted

## Context

A highly available infrastructure requires that resources be distributed across multiple physical Availability Zones (AZs) within an AWS region. This requires a robust networking design that provides redundant subnets, routing, and network gateways.

## Decision

We will implement a **Multi-AZ Network Topology with separate Public and Private Subnets** for each zone.

The architecture includes:
1.  **Availability Zone Distribution:** Spanning resources across a list of AZs (e.g., `["a", "b", "c"]`).
2.  **Public Subnets:** Each AZ receives its own public subnet with a dedicated route to a centralized Internet Gateway. These subnets are used for ALBs and NAT Gateways.
3.  **Private Subnets:** Each AZ receives its own private subnet with a route to a NAT Gateway (if public networking is enabled). These are used for ECS tasks, RDS instances, and caches.
4.  **Dedicated Route Tables:** Each AZ and each network type (public vs private) has its own Route Table to allow for future granular routing control between zones.

## Consequences

**Positive:**
*   **High Availability:** The infrastructure can survive the loss of a single (or multiple, depending on the number of AZs) Availability Zone.
*   **Logical Isolation:** Clearly separates public-facing resources (ALBs) from private backend resources (Databases, Apps).
*   **Routing Flexibility:** Having dedicated route tables for each AZ/Type allows for complex routing configurations (e.g., intra-AZ only traffic, cross-account VPC peering) without affecting the entire VPC.

**Negative:**
*   **Cost:** NAT Gateways are a significant recurring cost ($0.045 per hour + data transfer). Provisioning them in multiple AZs multiplies this cost.
*   **Resource Proliferation:** Creates many more subnets, route tables, and associations, which increases the complexity of the Terraform graph and the time to run a `terraform apply`.
*   **Complexity:** Management of CIDR block allocation for many subnets requires careful planning to avoid overlaps.