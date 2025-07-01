# Egress domain filtering

How to restrict what an infrastructure's private subnets can reach on the
internet to a list of domains. Placeholders: `<infrastructure>`,
`<environment>`, `<workspace>` (the full tfvars workspace name),
`<resource_prefix>`.

It is the v2 replacement for the v1 tinyproxy filter list, but it is
transparent: services need no `http_proxy`/`https_proxy` settings.

## What it does

An AWS Network Firewall sits between the private subnets and the NAT
gateway. Its stateful rule group is a domain allowlist on the TLS SNI and the
HTTP `Host` header: a TLS or HTTP request to any other domain is dropped and
logged. Traffic that is neither HTTP nor TLS (SSH, SMTP, database protocols,
raw TCP) is not filtered by the firewall; restrict it by port with
`infrastructure_vpc_network_acl_egress_lockdown_private` and
`infrastructure_vpc_network_acl_egress_custom_rules_private`.

Traffic inside the VPC, traffic from the public subnets and inbound traffic to
the load balancers never passes through the firewall.

## Turn it on

```hcl
infrastructure_vpc_egress_domain_filtering_allow_list = [
  ".example.com",     # example.com and every subdomain
  "api.example.org",  # that host only
]
```

Entries are lower-case hostnames, optionally with a leading dot to include
subdomains. Wildcards, schemes, ports and paths are rejected.

The platform's own destinations are added automatically and do not need
listing:

- `.amazonaws.com` (ECS, ECR, S3, SSM, CloudWatch, STS, KMS, OS package
  repositories)
- `.<datadog site>` when the Datadog agent is enabled
- the `infrastructure_ecs_cluster_syslog_endpoint` host
- any host in `infrastructure_ecs_cluster_logspout_command`
- for S3-to-Azure jobs: Docker Hub (`registry-1.docker.io`,
  `auth.docker.io` and its CloudFront and Cloudflare layer CDNs, as the task
  image is pulled from there), `login.microsoftonline.com` and each job's
  destination host

Edit the cached tfvars for `<workspace>`, then:

```
dalmatian terraform-dependencies set-tfvars -i <workspace>
dalmatian deploy infrastructure -i <infrastructure> -e <environment>
```

Planning fails if the infrastructure lacks public or private subnets, if the
ECS cluster is publicly available (its instances would bypass the NAT
gateway), or if the VPC is too small to keep its last public /24 free.

### What the first apply changes

- Two /28 subnets are created in the last /24 of the public half of the VPC,
  in the NAT gateway's availability zone: one for the firewall endpoint and
  one for the NAT gateway. Both use the public network ACL.
- **The NAT gateway is replaced** to move it into its subnet. It keeps its
  Elastic IP, so third parties that allowlist the address are unaffected, but
  outbound connections from the private subnets fail for a few minutes during
  the apply, and established connections are reset. Schedule it.
- The private route table's default route moves from the NAT gateway to the
  firewall endpoint.

Turning it off reverses all of this, with the same NAT gateway replacement.

### Cost

One firewall endpoint (billed hourly) plus a per-GB charge on everything
leaving the private subnets. AWS waives the NAT gateway's own charges for
traffic that has passed through a firewall endpoint in the same zone, which
offsets part of it.

## Find out what was blocked

Drops are written to the alert log group
`/aws/vendedlogs/<resource_prefix>-infrastructure-egress-domain-filtering`.
Each entry carries the source and destination addresses and, in
`event.tls.sni` or `event.http.hostname`, the domain that was refused.

```
dalmatian aws exec -i <infrastructure> -e <environment> logs tail \
  /aws/vendedlogs/<resource_prefix>-infrastructure-egress-domain-filtering \
  --since 1h --format short
```

Add the domain to the allow list and deploy; rule group updates apply
without interrupting traffic.

## Limits

- `.amazonaws.com` lets the private subnets reach any AWS endpoint, including
  S3 buckets in other accounts. Use VPC endpoint policies if that matters.
- A client that sends no SNI, or a non-TLS protocol on port 443, is not
  dropped by the domain list.
- There is one firewall endpoint, in the NAT gateway's zone, matching the
  single NAT gateway. Losing that zone loses egress, as it already did.
