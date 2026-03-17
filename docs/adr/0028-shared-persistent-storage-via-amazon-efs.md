# 28. Shared Persistent Storage via Amazon EFS

Date: 2023-12-22

## Status

Accepted

## Context

Many containerized applications require persistent storage that can be shared across multiple tasks running on different EC2 hosts (e.g., CMS media uploads, shared configuration files). Standard Amazon EBS volumes are block-level devices that can typically only be attached to a single EC2 instance at a time, making them unsuitable for multi-node ECS clusters.

## Decision

We will use **Amazon Elastic File System (EFS)** as the primary solution for persistent, shared storage for ECS application tasks.

The implementation:
1.  Terraform provisions an EFS file system with encryption at rest and lifecycle policies for cost optimization (`efs-infrastructure.tf`).
2.  Mount targets are created in each private subnet across the Multi-AZ topology.
3.  The ECS cluster's User Data is configured to automatically mount the EFS volume to a standardized path on every container instance.
4.  ECS Task Definitions can then use Docker `volume` and `mountPoint` configurations to map directories from the EFS mount on the host into the container.

## Consequences

**Positive:**
*   **Highly Available:** EFS is a regional service that spans multiple AZs, ensuring data is available even if an AZ fails.
*   **Scalable:** EFS automatically scales storage and throughput as files are added or accessed.
*   **Simple Sharing:** Multiple tasks running on different hosts can read from and write to the same file system simultaneously.

**Negative:**
*   **Cost:** EFS is significantly more expensive per GB than EBS, although this is mitigated by lifecycle policies that transition infrequently accessed data to a cheaper tier.
*   **Latency:** As a network-attached file system, EFS has higher latency than locally attached EBS volumes, which may impact performance for highly I/O-intensive workloads (e.g., database files).
*   **Complexity:** Requires managing NFS security groups and mounting logic within the EC2 User Data script.