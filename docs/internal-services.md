# Internal services

How to run an ECS service that only other tasks on the same cluster can
reach, over HTTPS, by name. Placeholders: `<infrastructure>`,
`<environment>`, `<service>`, `<domain>` (the infrastructure's Route53
domain, `<environment>.<infrastructure>.<root zone>`).

## Declare one

```hcl
infrastructure_ecs_cluster_services = {
  <service> = {
    container_port    = 8080
    alb_scheme        = "internal"
    deployment_type   = "rolling"
    enable_cloudfront = false
  }
}
```

An internal service must have `deployment_type = "rolling"` set, on the
service or in the service defaults; leaving it unset is rejected like
blue-green. Validation also rejects CloudFront, `domain_names` and a missing
`container_port`. Planning fails if the infrastructure has no Route53 hosted
zone (no wildcard certificate) or no private subnets; without the hosted zone
the plan also shows "Invalid index" errors for the certificate and zone
alongside that message.

The public ALB is still created whenever any service exists, so an
infrastructure with public subnets disabled cannot run services, internal or
not.

Callers use `https://<service>.<domain>`. The certificate is the
infrastructure wildcard, so any default TLS client verifies it; no custom CA
or plain-HTTP exception is needed.

## What gets built

The first internal service creates one shared internal Application Load
Balancer in the private subnets, with:

- an HTTPS listener on 443 (wildcard certificate, the same TLS policy as the
  public ALB) whose default action is `421 Misdirected Request`; there is no
  port 80 listener
- a security group accepting 443 only from the container-instance security
  group, and a matching container-instance rule accepting the dynamic port
  range from it
- access logs in the existing service ALB logs bucket when those are
  enabled; the load balancer name in each object key tells the two apart

Each internal service gets a host-header rule on that listener and an A
alias record `<service>.<domain>` in the infrastructure hosted zone. It gets
no rule on the public ALB, so the public ALB answers 421 for its host name,
and no CloudFront distribution or public-ALB record. Request-based
autoscaling measures it on the internal ALB.

## Network ACL lockdown

The security groups above are all the feature creates. If the infrastructure
sets `infrastructure_vpc_network_acl_ingress_lockdown_private` or
`infrastructure_vpc_network_acl_egress_lockdown_private` (or the public ones
while container instances run in public subnets), the network ACLs drop this
traffic until custom rules allow it, and callers see timeouts and the target
group reports unhealthy. Allow, from and to the VPC CIDR:

- into the private subnets: TCP 443 (callers to the internal ALB) and TCP
  32768–65535 (the ALB to tasks, when instances run in private subnets)
- out of the private subnets: TCP 1024–65535 (responses and the ALB to tasks)
- on the instances' subnets, if they are public: TCP 32768–65535 in from the
  ALB, and TCP 443 out to it with the return traffic on TCP 1024–65535 in

Use the matching `infrastructure_vpc_network_acl_*_custom_rules_*`
variables.

## Idle timeout

The ALB idle timeout is 60 seconds. A caller that lets a request run longer
than that will see the connection closed first; raise the timeout here
before raising the caller's.

## Residual risks

- Every task on the cluster can reach every internal service. Tasks use
  bridge networking and share the container-instance security group, so
  access cannot be narrowed to one calling service.
- Internal services keep the container instances' outbound rules, including
  HTTPS to anywhere.
- The record is in the public hosted zone, so it resolves for anyone and
  discloses private addresses. Nothing outside the VPC can connect to them.
- Traffic from the internal ALB to the task is HTTP inside the VPC, as it is
  for public services.

## Switching an existing service

A service cannot change `alb_scheme` in one apply: the old and new listener
rules and records would be created and destroyed with no ordering, the
records share a name, and a target group can sit behind only one load
balancer. Instead:

1. Empty the service's ECR repository; it is not force-deleted, so the
   destroy fails while it holds images.
2. Remove the service from `infrastructure_ecs_cluster_services` and deploy
   with `dalmatian deploy infrastructure -i <infrastructure> -e <environment>`.
3. Add it back with the new `alb_scheme` and deploy again.

The service is unavailable between the two applies. Its pipeline, ECR
repository and CloudWatch log group are destroyed and recreated, so its log
history is lost and the first deploy afterwards needs a fresh image build.
