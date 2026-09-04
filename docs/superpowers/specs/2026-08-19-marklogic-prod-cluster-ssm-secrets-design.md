# MarkLogic production cluster, with CloudFormation secrets sourced from SSM

Date: 2026-08-19

## Problem

Caselaw staging runs two Terraform-managed MarkLogic clusters through the
`custom_cloudformation_stacks` variable. Production's MarkLogic
(`caselaw-prod-marklogic-11`, created by hand in September 2023) is not managed by
Terraform at all. We want a Terraform-managed MarkLogic 11.3.6 cluster in
production, built from the same CloudFormation template staging uses.

The staging stacks pass the MarkLogic administrator password to CloudFormation as
a literal string in the tfvars file. Anyone with read access to the tfvars S3
bucket can read both cluster passwords. The new production cluster must not repeat
this, so `custom_cloudformation_stacks` needs a way to source parameter values from
AWS SSM Parameter Store.

## Goals

- A generic mechanism for sourcing any CloudFormation stack parameter from SSM
  Parameter Store, usable by any Dalmatian infrastructure, not just MarkLogic.
- A new MarkLogic 11.3.6 cluster in the caselaw production account, Terraform
  managed, with its administrator password held only in SSM.
- No behavioural change for the existing staging clusters.

## Non-goals

These are deliberately excluded and should be raised as separate work:

- Migrating data from `caselaw-prod-marklogic-11` to the new cluster.
- Application cutover: the `/caselaw/editor/prod/MARKLOGIC_*` and
  `/caselaw/priv-api/prod/MARKLOGIC_*` parameters continue to point at the old
  cluster.
- Decommissioning `caselaw-prod-marklogic-11`.
- Backup configuration for the new cluster.
- Migrating the two staging clusters' plaintext passwords to the new mechanism.
- Tightening the `marklogic-cloudformation` instance profile. It currently has
  `IAMFullAccess` plus eight other `*FullAccess` managed policies attached, which
  is a privilege escalation path from any node in the cluster.

## Why not CloudFormation-native secret resolution

Two CloudFormation features look like they should solve this, and neither does:

- `{{resolve:ssm-secure:name:version}}` dynamic references are only honoured in a
  fixed allowlist of resource properties. The template uses `!Ref AdminPass` inside
  instance UserData, which is not on that list.
- The `AWS::SSM::Parameter::Value<String>` parameter type resolves plaintext SSM
  parameters only, never `SecureString`.

Resolution therefore has to happen in Terraform, which then passes the resolved
value to CloudFormation as an ordinary stack parameter.

## Design: `ssm_parameters`

`custom_cloudformation_stacks` gains an optional `ssm_parameters` field mapping
CloudFormation parameter names to SSM parameter names:

```hcl
custom_cloudformation_stacks = {
  marklogic-202608 = {
    s3_template_store_key = "11/mlcluster.11.3.6.template"
    parameters            = { AdminUser = "caselaw-prod-marklogic" } # ...
    ssm_parameters        = { AdminPass = "/caselaw/marklogic-202608/prod/ADMIN_PASSWORD" }
  }
}
```

Four files change:

`variables.tf` adds `ssm_parameters = optional(map(string), {})` to the object
type, documents it in the existing description heredoc, and adds a validation block
asserting that no key appears in both `parameters` and `ssm_parameters` for the
same stack, so precedence is never ambiguous.

`locals.tf` adds two locals. The first flattens the per-stack maps into a single
map keyed `"<stack>:<parameter>"`, giving `for_each` a stable, statically known key
set:

```hcl
custom_cloudformation_stack_ssm_parameters = merge([
  for stack_key, stack in local.custom_cloudformation_stacks : {
    for param_key, ssm_name in stack["ssm_parameters"] :
    "${stack_key}:${param_key}" => ssm_name
  }
]...)
```

The second produces the final parameter map per stack, with SSM values overlaid on
the literal parameters:

```hcl
custom_cloudformation_stack_parameters = {
  for stack_key, stack in local.custom_cloudformation_stacks :
  stack_key => merge(
    coalesce(stack["parameters"], {}),
    {
      for param_key, ssm_name in stack["ssm_parameters"] :
      param_key => data.aws_ssm_parameter.custom_cloudformation_stack["${stack_key}:${param_key}"].value
    }
  )
}
```

`data.tf` adds the data source. `SecureString` values are decrypted by default:

```hcl
data "aws_ssm_parameter" "custom_cloudformation_stack" {
  for_each = local.custom_cloudformation_stack_ssm_parameters
  name     = each.value
}
```

`cloudformation-custom-stack.tf` changes `parameters = each.value["parameters"]` to
`parameters = local.custom_cloudformation_stack_parameters[each.key]`.

### Consequences

The parameter must exist before `terraform plan` runs, or the plan fails with
`ParameterNotFound`. This is preferable to the alternative of creating a cluster
with an empty administrator password.

The AWS provider marks `data.aws_ssm_parameter.value` as sensitive, so merging it
renders that stack's whole `parameters` map as `(sensitive value)` in plan output.
Sensitivity is per resource instance, so stacks that do not use `ssm_parameters`
still show their parameters in full. The same resource already wraps `template_url`
in `sensitive()`, so this is consistent with existing behaviour.

Stacks with an empty `ssm_parameters`, which is every stack that exists today,
produce a byte-identical parameter map. A plan against caselaw staging showing no
changes to its two stacks is the regression test for this.

Terraform state holds the resolved password. State lives in the encrypted
`dxw-dalmatian-tfstate` bucket, and the value is equally readable through
`aws ssm get-parameter --with-decryption`, so this does not widen access in
practice.

The `ssm_parameters` mechanism resolves values once, at stack create or update
time. It is not a rotation mechanism: `AdminPass` is only referenced in instance
UserData, so MarkLogic applies it during initial cluster bootstrap. Changing the
SSM value later rewrites the launch configuration without changing the live
cluster's administrator password.

## Design: the production cluster

The stack key is `marklogic-202608`, named for its creation year and month rather
than its MarkLogic version. The key is effectively immutable, because changing it
destroys and recreates the stack, and a version-derived name would go stale the
first time `s3_template_store_key` is pointed at a newer template to pick up a new
AMI.

Production's `resource_prefix` is `dxw-dalmatian-caselaw-prod`, so
`resource_prefix_hash` is `3d06b7b2`. This gives a CloudFormation stack named
`cf-3d06b7b2-marklogic-202608`, with `ManagedEniStack` and `NodeMgrLambdaStack`
children, and a template bucket named
`3d06b7b2-cloudformation-custom-stack-templates`.

Parameter values, with their provenance:

| Parameter | Value | Source |
| --- | --- | --- |
| `s3_template_store_key` | `11/mlcluster.11.3.6.template` | copied from the staging template bucket |
| `IAMRole` | `marklogic-cloudformation` | existing production instance profile |
| `KeyName` | `marklogic-cloudformation` | existing production key pair |
| `InstanceType` | `t3.xlarge` | matches `caselaw-prod-marklogic-11` |
| `VolumeSize` | `500` | matches `caselaw-prod-marklogic-11` |
| `VolumeType` | `gp3` | upgrade from the old stack's `gp2` |
| `VolumeIOPS` | `3000` | template default |
| `VolumeThroughput` | `125` | template default |
| `VolumeEncryption` | `enable` | matches `caselaw-prod-marklogic-11` |
| `VolumeEncryptionKey` | `""` | matches `caselaw-prod-marklogic-11` |
| `NumberOfZones` | `3` | matches `caselaw-prod-marklogic-11` |
| `NodesPerZone` | `1` | matches `caselaw-prod-marklogic-11` |
| `AZ` | `eu-west-2a,eu-west-2b,eu-west-2c` | matches `caselaw-prod-marklogic-11` |
| `SpotPrice` | `0` | matches `caselaw-prod-marklogic-11` |
| `LogSNS` | `none` | matches `caselaw-prod-marklogic-11` |
| `VPC` | `vpc-0df87826529c1d490` | `dxw-dalmatian-caselaw-prod-infrastructure` |
| `PublicSubnet1` | `subnet-03d716daeffebfe12` | Dalmatian public subnet, eu-west-2a |
| `PublicSubnet2` | `subnet-0bf8172d07a5c6d51` | Dalmatian public subnet, eu-west-2b |
| `PublicSubnet3` | `subnet-0ed788c7e63c6f5aa` | Dalmatian public subnet, eu-west-2c |
| `PrivateSubnet1` | `subnet-0fa90cd0842cba29a` | Dalmatian private subnet, eu-west-2a |
| `PrivateSubnet2` | `subnet-077995ea5555c8132` | Dalmatian private subnet, eu-west-2b |
| `PrivateSubnet3` | `subnet-04429c77f3048ad49` | Dalmatian private subnet, eu-west-2c |
| `ExternalAccessCidrIP` | `54.76.254.148/32` | matches production and staging |
| `ECSSecurityGroup` | `sg-05f0edaea0288d3c5` | current production ECS container instances security group |
| `AdminUser` | `caselaw-prod-marklogic` | matches `caselaw-prod-marklogic-11` |
| `Licensee` | `The National Archives - Unrestricted` | matches `caselaw-prod-marklogic-11` |
| `LicenseKey` | copy verbatim from `aws cloudformation describe-stacks --stack-name caselaw-prod-marklogic-11` | matches `caselaw-prod-marklogic-11` and staging |
| `AdminPass` | via `ssm_parameters` | `/caselaw/marklogic-202608/prod/ADMIN_PASSWORD` |

Also `on_failure = "DO_NOTHING"` and
`capabilities = ["CAPABILITY_NAMED_IAM", "CAPABILITY_IAM", "CAPABILITY_AUTO_EXPAND"]`,
as staging uses.

Two details are easy to get wrong:

The old stack passes `ECSSecurityGroup = sg-0e78026d5e85d721c`, a security group
that no longer exists. Copying that value forward would produce a cluster
unreachable from ECS. The current equivalent is `sg-05f0edaea0288d3c5`,
`dxw-dalmatian-caselaw-prod-infrastructure-ecs-cluster-container-instances`, which
is also what staging passes.

No `ClusterName`, `PublicLoadBalancer` or `InternalLoadBalancer` parameters. Those
exist only in the MarkLogic 12 template that staging's other stack uses. Passing a
parameter the template does not declare fails the stack outright.

## Rollout

Each step is separately verifiable, and the ordering is load bearing.

1. Branch from `origin/main` in `terraform-dxw-dalmatian-infrastructure`, make the
   module change, run `terraform validate`, and push the branch.
   `terraform-dependencies clone -i <ref>` clones from GitHub rather than from the
   local working copy, so the branch has to be pushed before
   `~/bin/update-dalmatian-infrastructure-module.sh` can pick it up. Re-pushing
   means re-running that script. No release and no
   `terraform-project-versions.json` bump: the branch is used directly for testing.
2. Plan against `caselaw-staging` and confirm no changes to its two MarkLogic
   stacks. This is the regression check, and it comes before production is touched.
3. Create the secret in account `276505630421`: 32 alphanumeric characters, since
   the template's `AllowedPattern` on `AdminPass` rejects `*`. Store it with
   `aws ssm put-parameter --type SecureString --name
   /caselaw/marklogic-202608/prod/ADMIN_PASSWORD`, and record it in the team
   password store. Nothing references it yet.
4. Set `enable_cloudformatian_s3_template_store = true` in the production tfvars
   (`200-E276505630421-eu-west-2-caselaw-caselaw-prod.tfvars`), plan, apply. This
   creates `3d06b7b2-cloudformation-custom-stack-templates`.
5. Copy `11/mlcluster.11.3.6.template` from staging's
   `58785dac-cloudformation-custom-stack-templates` to the same key in the
   production bucket. The accounts differ, so download then upload, and verify the
   checksum matches afterwards. This must precede step 6: the module presigns the
   object URL at plan time, and CloudFormation gets a 404 if the object is missing.
6. Add the `marklogic-202608` stack block to the production tfvars, plan, review,
   apply. The stack and its two children take roughly 20 to 30 minutes. Verify
   using the stack's `URL` output on port 8001 and an admin login with the SSM
   value.
7. Add `mark-logic-202608-egress-1` (tcp 8000 to 8011) and
   `mark-logic-202608-egress-2` (tcp 7997 to 7998) to
   `infrastructure_ecs_cluster_custom_security_group_rules`, targeting the new
   stack's `InternalElbSecurityGroup`. This is necessarily a second apply, because
   that security group does not exist until step 6. The existing rules targeting
   `sg-0a411fd600e4cce26` stay in place so the old cluster keeps serving traffic.

Steps 4, 6 and 7 are tfvars edits made through
`dalmatian terraform-dependencies set-tfvars`, which stores them in the
`<project-hash>-tfvars` S3 bucket. They are not version controlled, so only the
step 1 module change is reviewable as a pull request.

## Incidental fix

The `enable_cloudformatian_s3_template_store` variable description claims "A user
with RW access to the bucket is also created". No such user exists in
`cloudformation-custom-stack-s3-template-store.tf`. Correct the description while
editing the neighbouring variable.
