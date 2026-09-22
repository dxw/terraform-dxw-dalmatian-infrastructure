# Sidecar containers

How to run an extra container alongside a service's application container,
how the application reaches it, what stays private, and where the evidence
lives. Placeholders: `<infrastructure>`, `<environment>`, `<service>`,
`<sidecar>`, `<workspace>`.

## Declare a sidecar

In the infrastructure's tfvars (`dalmatian terraform-dependencies set-tfvars`):

```hcl
infrastructure_ecs_cluster_services = {
  <service> = {
    sidecar_containers = {
      <sidecar> = {
        image              = "docker.io/<org>/<image>@sha256:<64 hex digest>"
        container_port     = 3000
        memory_reservation = 512
        command            = ["<binary>", "--flag=value"]
        environment        = [{ name = "LOG_LEVEL", value = "info" }]
      }
    }
  }
}
```

Deploy with `dalmatian deploy infrastructure -i <infrastructure> -e <environment>`.

- `image` must be a digest reference. A tag is rejected at plan time, so the
  running image can only change by editing the digest in tfvars. Any registry
  is accepted, but the mirror only authenticates to Docker Hub (using the
  infrastructure's `infrastructure_dockerhub_*` settings when present), so an
  image elsewhere must be publicly pullable.
- `command` and `environment` are passed to the container verbatim. The
  module adds nothing and removes nothing, so the flags you declare are the
  flags that run.
- `memory_reservation` is the soft limit in MiB (default 256). Size it for
  the sidecar's real working set; a headless browser needs several hundred.
- `container_port` is informational: it documents the port the application
  will use but nothing publishes it.
- `essential` defaults to `true`: if the sidecar exits, the whole task stops
  and ECS replaces it, so a task never serves traffic with a dead sidecar.
  Set it to `false` only for a sidecar the application can run without.
- The sidecar name must differ from the service name and be a lower-case
  DNS-style label (letters, digits and single hyphens, not ending in a
  hyphen), because the application resolves it as a hostname and it forms
  part of the ECR repository name.

Deploying the first sidecar for a service adds an ECR repository, a
CodeBuild mirror project and its IAM role, a `terraform_data` trigger and a
pull policy on the service's task execution role, then registers a new task
definition revision. The AWS provider registers containers sorted by name,
so the application is not necessarily first in the definition; everything in
the platform that needs the application container finds it by name (the
container name is the service name), never by position.

How the service moves to that revision depends on its `deployment_type`:

- **Blue/green**: the apply itself creates a CodeDeploy
  deployment for the new revision, so the sidecar is live once that
  deployment completes.
- **Rolling**: nothing in the apply or the build pipeline moves the service.
  The pipeline's ECS deploy action starts from the service's *current*
  task definition and only swaps the application image, so it never picks
  up a revision registered by Terraform. Point the service at the latest
  revision once, by family name, which resolves to the newest active
  revision:

  ```
  dalmatian aws exec -i <infrastructure> -e <environment> ecs update-service \
    --cluster <prefix>-infrastructure \
    --service <service> \
    --task-definition <prefix>-<service>
  ```

  Later pipeline runs build on that revision, so the sidecar persists. The
  same applies to any Terraform-driven task definition change on a rolling
  service (volumes, extra hosts, ports), not only sidecars.

## How the application reaches it

Set the application's host and port for the sidecar to the sidecar name and
the port the sidecar listens on, for example `GOTENBERG_HOST=gotenberg` and
`GOTENBERG_PORT=3000` via `dalmatian service set-environment-variables`.

The task runs in Docker bridge networking and the application container is
linked to every sidecar, so `http://<sidecar>:<port>` resolves inside the
application container and nowhere else. To check from inside the application
container (`container-access` opens the container named after the service):

```
dalmatian service container-access -i <infrastructure> -e <environment> -s <service>
curl -s -o /dev/null -w '%{http_code}\n' http://<sidecar>:<port>/health
```

## What is and is not exposed

- The sidecar has no `portMappings`, so Docker publishes no host port for it
  and the ALB cannot target it. On the instance, `docker port <container>`
  for the sidecar prints nothing.
- Only the application container is registered with the ALB target group.
- **Shared task role:** ECS serves the task role's credentials to every
  container in the task, so a sidecar can call anything the service's task
  role allows. There is no per-container IAM. A sidecar image is therefore
  trusted with the service's AWS permissions, which is why images must be
  digest-pinned and are mirrored rather than pulled from the source
  registry. A helper that must not hold those permissions belongs in its own
  service with its own task role. The execution role is used by the ECS
  agent to pull images and ship logs and is not exposed to containers.
- **Residual:** every container on the same instance shares the Docker
  bridge, so another container on that host could reach the sidecar's
  container IP directly. Dalmatian clusters are single-tenant, so the only
  other containers are the same application's services and the platform's
  log and monitoring agents. Closing this needs `awsvpc` networking or
  host-level firewall rules and is deliberately out of scope; cite this
  paragraph if a security review asks.

## Image mirroring and evidence

The task never pulls from Docker Hub. On the first deploy, and again whenever
the digest in tfvars changes, a CodeBuild project pulls the digest reference,
tags it with the 64-hex digest and pushes it to a per-sidecar ECR repository
(`<prefix>-<service>/sidecar/<sidecar>`, immutable tags, scan on push). The
task definition references `<repository>:<digest hex>`. A re-run for a digest
that is already mirrored skips the pull and push. Images are kept until the
sidecar is removed, so a task definition revision can always pull the digest
it was registered with; each digest change adds one image.

The build log is the evidence that the configured digest is what was
mirrored. To read it:

```
dalmatian aws exec -i <infrastructure> -e <environment> codebuild list-builds-for-project \
  --project-name <prefix>-ecs-cluster-service-sidecar-<service>_<sidecar>-image-mirror --max-items 1
dalmatian aws exec -i <infrastructure> -e <environment> logs tail \
  /aws/codebuild/<prefix>-ecs-cluster-service-sidecar-<service>_<sidecar>-image-mirror --since 1d
```

Every build ends with `describe-images` JSON showing the ECR image digest,
tag and push time. The tag is the 64-hex digest from the configured source
reference and the repository's tags are immutable, so a matching tag means
that exact digest was pulled and pushed at `pushedAt`. The ECR `imageDigest`
is the digest of the single-platform copy stored in ECR and will differ from
a multi-platform source index.

Only the build that pulled the digest contains the line
`resolved=<registry>/<image>@sha256:<digest> os=linux arch=amd64`, which is
the source manifest that was pulled. A later run for the same digest, for
example after a buildspec change, prints `skipped=<source image>
tag=<digest>` instead. To find the pulling build for a digest, search the log
group rather than tailing the latest build:

```
dalmatian aws exec -i <infrastructure> -e <environment> logs filter-log-events \
  --log-group-name /aws/codebuild/<prefix>-ecs-cluster-service-sidecar-<service>_<sidecar>-image-mirror \
  --filter-pattern '"resolved=" "<digest>"' \
  --query 'events[].{time:timestamp,stream:logStreamName,message:message}'
```

To confirm what a running task declares:

```
dalmatian aws exec -i <infrastructure> -e <environment> ecs describe-task-definition \
  --task-definition <prefix>-<service> \
  --query 'taskDefinition.containerDefinitions[].{name:name,image:image,links:links,ports:portMappings,command:command}'
```

The container named after the service has `links` naming each sidecar; each
sidecar has an image ending in the digest hex, `ports: null`, and the exact
command from tfvars. Do not rely on the order of the list.

## Change or remove a sidecar

Changing the digest triggers a fresh mirror and a new task definition
revision. Changing the command or environment only registers a new revision.
Removing the block deletes the mirror project, its IAM, the execution role's
pull policy and the ECR repository (and the images in it), and drops the
container from the next revision.

The service does not move to a new revision on its own. Until it is
deployed, ECS keeps replacing failed or drained tasks from the old revision,
which for a removed sidecar means pulling an image whose repository no
longer exists, so those replacement tasks cannot start. Treat "remove the
sidecar" and "deploy the service" as one operation:

- Blue/green services: the apply itself creates the CodeDeploy deployment
  for the new revision, so the window is the deployment's duration. Watch it
  complete.
- Rolling services: run the `ecs update-service` command from "Declare a
  sidecar" immediately after the apply. `dalmatian service deploy` alone is
  not enough, because the pipeline deploys from the service's current
  revision.

Changing a digest is safe in this respect: the old image stays in the
repository, so the old revision remains startable until you deploy.

## Out of scope

`awsvpc` networking, sidecar secrets (use plain environment values only for
non-secret configuration), sidecar volumes, and `dependsOn` ordering or
container health checks between the application and its sidecars. The
application's own readiness probe should fail while a required sidecar is
unreachable.

Scheduled tasks declared under `scheduled_tasks` run the application image
alone, without sidecars, so a scheduled entrypoint must not depend on one.
