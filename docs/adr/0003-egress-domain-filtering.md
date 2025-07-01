# 3. Egress domain filtering with Network Firewall

Date: 2026-11-09

## Status

Accepted

## Context

Some clients require that their hosting can only reach an agreed list of
internet destinations. On v1 this was met for one client with a tinyproxy
service and a filter list, which only works for software that honours
`http_proxy`/`https_proxy`, and is another service for the platform to run.
v2 runs services in private subnets that leave through a single NAT gateway
in the first availability zone.

## Decision

An AWS Network Firewall with a stateful domain list (allowlist on TLS SNI and
HTTP `Host`) inspects private-subnet egress, enabled by giving
`infrastructure_vpc_egress_domain_filtering_allow_list` any entries.
Domains the platform needs are added automatically, so the list only carries
what the client's applications need.

The firewall needs symmetric routing, so responses arriving at the NAT gateway
must route back through the endpoint. That return route cannot live on the
public route table: the ALBs share it, and ALB-to-task traffic would then go
through the firewall in one direction only. The NAT gateway is therefore moved
into a dedicated subnet with its own route table, next to a dedicated firewall
subnet, both /28s carved from the unused last /24 of the public half of the
VPC. There is one endpoint, in the NAT gateway's zone, matching the existing
single-NAT design.

## Consequences

Filtering is transparent to applications and is managed AWS infrastructure
rather than a platform-run proxy. Only HTTP and TLS are filtered; other
protocols rely on the existing private egress network ACL rules. Enabling or
disabling the feature replaces the NAT gateway (keeping its Elastic IP), which
interrupts private egress for a few minutes. Clusters with publicly available
instances, public-only VPCs and VPCs too small to spare their last public /24
cannot use it. A multi-NAT, multi-endpoint layout is a follow-up if zone
resilience for egress is wanted.
