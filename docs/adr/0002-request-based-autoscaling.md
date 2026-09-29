# 2. Request-based autoscaling

Date: 2026-09-29

## Status

Accepted

## Context

Services ran a fixed task count and clusters a fixed instance count, with
only cron schedules to change them. A service that needs to absorb bursts
had to be over-provisioned permanently. Every container reserved 16 MiB,
so ECS could neither place tasks on real capacity nor tell when a cluster
was full.

## Decision

Services opt into Application Auto Scaling target tracking on ALB
requests per target. Each service gets one policy whose metric is the sum
of `RequestCountPerTarget` over every target group it has, with missing
data filled as zero, so a blue/green service's idle colour and a quiet
site both count as zero requests rather than leaving the scale-in alarm
without data. Every service is registered as a scalable target so
Terraform can stop managing `desired_count` without breaking
`container_count`. Clusters opt into an ECS capacity provider with
managed scaling over their ASG; managed termination protection stays off
because it blocks the nightly instance refresh, and draining stays with
the existing lifecycle hook. Services declare real memory and CPU
reservations. ECS cannot switch a service from the EC2 launch type to a
capacity provider in place, so opting in an existing cluster makes
Terraform replace its services (destroy, then create, in one apply). That
only happens on the cluster whose variable changes, so no other cluster
can be affected by a release.

## Consequences

Clusters and services that do not opt in keep their running services and
instances as they are, with two changes in what an apply does: it no
longer resets a service's desired count to `container_count` (the
scalable target's min and max enforce it instead), and it no longer
resets the ASG's desired capacity, so lowering `min_size` no longer
shrinks a cluster by itself while raising it still grows one. Opted-in
clusters scale instances on task reservations, so the reservations must
be honest; opting in replaces the cluster's services and triggers an
instance refresh, and a recreated blue/green service attaches to blue.
Managed scale-in relies on the draining Lambda, which the capacity
provider now requires. CPU-based scaling, managed draining and managed
termination protection are follow-ups.
