# Agent instructions

Terraform for dxw's Dalmatian v2 hosting platform. Applied per infrastructure
and environment by `dalmatian deploy infrastructure` from `dalmatian-tools`,
which pins a release of this repo in `terraform-project-versions.json`.

## Checks before every commit

```
terraform fmt -check
terraform validate
tflint -f compact
terraform-docs .
```

CI runs all four. `terraform-docs` rewrites the `README.md` block between the
`BEGIN_TF_DOCS` and `END_TF_DOCS` markers, so regenerate it in the same commit
as any variable, output or resource change. `terraform validate` needs a
`terraform init`; the checked-in `backend.tf` points at S3, so a scratch
directory with an empty `main.tf` is the quickest place to run
`terraform console` for expression and `templatefile` checks.

## Things that are easy to get wrong here

- **ECS containers are found by name, never by position.** The AWS provider's
  `container_definitions` sorts containers by name before registering them,
  so with more than one container (see `sidecar_containers`) the application
  is at index 0 only when its name sorts first. The application container is
  always named after the service. Buildspecs, scripts and docs must select
  `.name == $CONTAINER_NAME`, never `containerDefinitions[0]`.
- **Every file under `buildspecs/` is uploaded verbatim to every
  infrastructure's buildspec store** (`fileset` in the S3 object resource), so
  adding or changing a buildspec changes every infrastructure that has
  services. Buildspecs the platform's own CodeBuild projects inline (Datadog,
  logspout, utilities, sidecar mirror) are additionally rendered through
  `templatefile`, so in those files `${` or `%{` must be escaped as `$${` or
  `%%{`; service buildspecs read back from S3 are not templated.
- **Additive features must leave existing infrastructures alone.** Default new
  attributes so an unchanged tfvars file plans no resource changes. Verify on
  the `test`/`staging` scratch workspace in the main Dalmatian account: plan
  with the unchanged cached tfvars, then edit the cached tfvars locally to
  exercise the feature, and restore the cache with
  `dalmatian terraform-dependencies get-tfvars` afterwards. Never upload
  scratch tfvars.
- **`container-definitions/*.tpl` render checks are cheap.** Call
  `templatefile` with literal inputs in a scratch `terraform console` and pipe
  the result through `jq` to assert on the rendered JSON before relying on a
  plan.
- **Third-party images are mirrored, never pulled at task launch.** Follow the
  Datadog, logspout and sidecar mirror pattern: an ECR repository plus a
  CodeBuild project triggered by `terraform_data`.
- **Service object attributes exist in two variables.** Anything added to
  `infrastructure_ecs_cluster_services` must also be added to
  `infrastructure_ecs_cluster_service_defaults`, documented in the services
  description heredoc, and merged through `local.infrastructure_ecs_cluster_services`
  in `locals.tf`.

## Conventions

- One `.tf` file per concern, named `<area>-<resource>.tf`; IAM policies and
  container definitions come from `.tpl` files under `policies/` and
  `container-definitions/`.
- IAM names are `${local.resource_prefix}-${substr(sha512("<purpose>"), 0, 6)}`
  with the purpose in `description`.
- Runbooks live in `docs/`, ADRs in `docs/adr/`. Designs and plans live in the
  central spec store, not in this repo.
- Releases are tags `vX.Y.Z` cut with `gh release create --generate-notes`;
  Renovate opens the `dalmatian-tools` pin bump.
- No account IDs, hostnames or client identifiers in commits, PR text or docs.
