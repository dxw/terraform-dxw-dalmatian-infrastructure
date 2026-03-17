# Features of dxw Dalmatian Infrastructure

This module provides a comprehensive suite of tools to create and manage infrastructure within an AWS account for applications running on dxw's Dalmatian hosting platform.

## Core Features

### 1. Networking & VPC Management
The module handles robust networking topologies tailored for secure application hosting.
* **VPC & Subnets:** Automated provisioning of VPCs with configurable public and private subnets across multiple Availability Zones.
* **Network ACLs:** Lock down inbound and outbound traffic with explicitly configured network access control lists (NACLs), providing deep defense-in-depth configurations.
* **VPC Flow Logs:** Collect VPC flow logs and direct them to CloudWatch or an S3 bucket. Automatically provisions Athena Workgroups and Glue Data Catalogs to enable seamless SQL querying of flow logs directly from the AWS Console.
* **Bastion Host:** An optionally enabled EC2 Bastion host accessible via AWS Systems Manager Session Manager (SSM), keeping SSH ports closed.
* **Global Accelerator:** Integration with AWS Global Accelerator for improved global network performance to Application Load Balancers.

### 2. Compute & Container Orchestration (ECS)
At its core, this module provides container orchestration utilizing Amazon ECS backed by EC2 auto-scaling groups.
* **EC2-backed ECS Clusters:** Manages ECS clusters powered by EC2 instances for fine-grained control over instance types, caching, and host-level monitoring.
* **Advanced Autoscaling:** Scales instances based on CPU utilization and time-based cron schedules (min/max instances).
* **Automated Instance Management:** Provides Lambda-backed workflows for automated ECS EC2 instance draining and instance refreshes, ensuring high availability during scale-ins and AMI updates.
* **Observability Tooling:** Built-in Datadog agent provisioning and Logspout container deployments for robust, centralized monitoring and log aggregation. Supports Container Insights configuration.

### 3. Service Deployments & CI/CD
Deploying applications is fully managed, offering a paved road from code to production.
* **CodePipeline & CodeBuild Integration:** Built-in integration with GitHub for automated continuous integration and delivery.
* **Deployment Strategies:** Supports both rolling deployments and robust Blue/Green deployments using AWS CodeDeploy.
* **ALB & CloudFront Integration:** Services are fronted by Application Load Balancers. You can optionally place a CloudFront distribution in front of your service.
* **CloudFront Bypass Protection:** Security feature that enforces a secret header checked by ALB listener rules, ensuring traffic must flow through CloudFront and cannot directly access the ALB.
* **Scheduled Tasks:** Allows running asynchronous scheduled tasks (cron jobs) against your service's codebase.

### 4. Data Stores & Caching
Fully managed relational databases and in-memory caches.
* **Amazon RDS:** Deploy standard RDS instances or Aurora clusters. Supports configurable instance classes, storage, Multi-AZ deployments, and IOPS configurations.
* **Aurora Serverless v2:** Built-in support for scalable Serverless v2 instances for dynamic workloads.
* **Automated S3 Backups:** Besides native AWS backups, this module can provision scheduled ECS Fargate tasks to take SQL dumps of your databases and store them directly into an encrypted S3 bucket.
* **ElastiCache (Redis):** Provisions ElastiCache configurations, including the newer Redis Serverless offerings as well as standard cluster architectures.

### 5. Storage (Amazon S3) & Content Delivery
Versatile object storage configurations for assets and custom applications.
* **Custom S3 Buckets:** Provides configuration for secure S3 buckets (private, versioned, server-side encryption).
* **CloudFront Distributions:** Native capability to serve S3 bucket objects via CloudFront using Origin Access Control (OAC), removing the need for public buckets.
* **WAF Integration:** Seamlessly attach AWS WAFv2 Web ACLs to CloudFront distributions, configuring rate limits, IPv4/IPv6 allow/deny lists, and AWS managed rules.
* **Basic Authentication:** Viewer Request CloudFront functions available to implement Basic Auth on S3 CloudFront distributions.
* **VPC Transfer S3 Bucket:** Specialized bucket paired with SSM documents allowing easy file transfers from private VPC instances to secure storage.
* **EFS for ECS:** Elastic File System provisioning and mounting for shared storage across ECS tasks.

### 6. Security, Encryption & Miscellaneous
* **Centralized KMS Encryption:** A single, central KMS key architecture for broad infrastructure encryption at rest (with options for dedicated RDS/S3 keys).
* **Custom Lambda Deployments:** Deploy ad-hoc Python/Node/etc. AWS Lambda functions dynamically from zips in an S3 template store, fully hooked into the VPC and custom IAM policies.
* **Route 53 Management:** Automated creation of Hosted Zones and arbitrary DNS records (A, CNAME, MX, TXT).
* **CloudFormation Templates:** Native ability to deploy custom CloudFormation stacks alongside your Terraform configuration to fill any feature gaps.
* **Resource Tagging:** Custom script to recursively apply mandatory tags to all spawned AWS resources that don't natively support robust Terraform tagging.