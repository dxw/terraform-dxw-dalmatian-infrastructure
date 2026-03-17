# 12. Defense-in-Depth via Mandatory Network ACLs

Date: 2023-11-22

## Status

Accepted

## Context

AWS VPC Security Groups are stateful firewalls that operate at the instance level. They are our primary line of defense for controlling ingress and egress traffic for our applications, databases, and caches. However, relying solely on Security Groups can be risky. A single permissive Security Group rule could accidentally expose critical internal resources to the public Internet if misconfigured.

## Decision

We will implement a **Defense-in-Depth network security model** by using both **Security Groups and Network Access Control Lists (NACLs)**.

Under this model:
1.  **Security Groups:** Continue to be used for fine-grained, stateful traffic control between specific resource tiers (e.g., Application -> Database).
2.  **Network ACLs (NACLs):** Are used as a second, stateless layer of protection at the subnet boundary. We will explicitly lockdown all subnets and only permit the minimum ports and protocols required for the module's core features (e.g., ports 80/443 for web traffic, ephemeral ports for established connections).
3.  **Default Rules:** The module provides flags (`infrastructure_vpc_network_acl_ingress_lockdown_private` and similar) that, when enabled, apply these restrictive NACL rules by default.

## Consequences

**Positive:**
*   **Defense-in-Depth:** Even if a Security Group is accidentally set to allow `0.0.0.0/0`, the NACL at the subnet level provides a final barrier that will drop unauthorized traffic.
*   **Compliance:** Meets many security frameworks' requirements for multi-layered network security.

**Negative:**
*   **Stateless Complexity:** Because NACLs are stateless, you must explicitly allow both inbound and outbound traffic, including ephemeral port ranges (e.g., 1024-65535). This can be difficult for developers to troubleshoot and easy to misconfigure.
*   **Administrative Burden:** Modifying network communication patterns now requires changes in two places: the Security Group (stateful) and the Network ACL (stateless).
*   **Rule Limits:** AWS VPCs have a hard limit on the number of NACL rules per ACL (usually 20-40), requiring careful rule management.