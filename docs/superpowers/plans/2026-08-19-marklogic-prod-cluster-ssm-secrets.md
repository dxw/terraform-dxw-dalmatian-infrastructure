# MarkLogic Production Cluster with SSM-Sourced Secrets Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an `ssm_parameters` field to `custom_cloudformation_stacks` so CloudFormation stack parameters can be sourced from SSM Parameter Store, then use it to deploy a Terraform-managed MarkLogic 11.3.6 cluster in the caselaw production account.

**Architecture:** Terraform resolves named SSM parameters with `data.aws_ssm_parameter` and merges the values over each stack's literal `parameters` map in a local, so `aws_cloudformation_stack.custom` receives a complete map without any secret appearing in tfvars. The production MarkLogic cluster is then a pure tfvars change using that field, deployed in a sequence of small applies because the CloudFormation template object and the cluster's security groups must exist before later steps can reference them.

**Tech Stack:** Terraform 1.12.0, AWS provider, `dalmatian` CLI v2 (SSO auth, tfvars in S3, workspace-per-environment), MarkLogic CloudFormation template 11.3.6, tflint.

## Global Constraints

- **Who runs what.** Every step is tagged `[agent]` or `[human]`. The agent edits
  files, including tfvars, and runs read-only AWS queries and the staging plan. The
  human runs everything that mutates AWS or the remotes: `dalmatian deploy` applies,
  `aws ssm put-parameter`, uploads to production S3, `git push`, and `gh pr create`.
  An agent that hits a `[human]` step stops, prints the exact command, and waits.
- The `dalmatian` CLI aborts with "There may be a newer version ... but cant update!"
  when `dalmatian-tools` is ahead of its latest tag, which it currently is
  (`v0.64.0-3-g48b856b`). Prefix every `dalmatian` invocation with
  `DALMATIAN_SKIP_UPDATE_CHECK=1`.
- **The two staging MarkLogic stacks have a pre-existing perpetual diff**, on `main`
  as much as on this branch. Two independent causes: CloudFormation reports `NoEcho`
  parameters as `****`, so `parameters["AdminPass"]` never matches the configured
  value; and `data.external.s3_presigned_url` mints a fresh presigned URL every plan,
  so `template_url` always differs. Consequently "no changes" is *not* the success
  criterion anywhere in this plan — see Task 2.
- Terraform version is pinned by `.terraform-version` to `1.12.0`. Use `tfenv install` / `tfenv use` if the local default differs.
- Repo has no unit test framework. The test cycle is: a scratch harness module for pure-HCL logic, then `terraform init -backend=false`, `terraform validate`, `terraform fmt -check`, and `tflint -f compact` in the repo, then a real `terraform plan` against caselaw staging showing **no changes**.
- CI runs `terraform init` + `terraform validate` (via the `hashicorp/terraform:1.12.0` image, with `backend.tf` removed) and `tflint v0.44.1`. Both must pass.
- Branch is `add-ssm-parameters-to-custom-cloudformation-stacks`, already created off `origin/main` at `6ec25ab`, with the design doc committed as `aeb9f39`.
- The repo working tree has four pre-existing untracked files: `CHANGELOG.md`, `GEMINI.md`, `TODO.md`, `s3-to-azure-debug-findings.md`. **Never** `git add .` or `git add -A`; always stage explicit paths.
- Commits are GPG signed (`commit.gpgsign=true`, key `94E63432B71CE3CB`). Before the first commit run:
  `printf 'test' | gpg --batch --no-tty --local-user "$(git config --get user.signingkey)" --detach-sign --output /dev/null -`
  Exit 0 means signing works non-interactively. Non-zero: stop and ask the user to unlock the key.
- Commit message style in this repo: imperative subject line under ~52 chars, blank line, body wrapped at ~72 chars explaining *why*.
- AWS access uses `export AWS_CONFIG_FILE=~/.config/dalmatian/dalmatian-sso.config` with profile `caselaw` (production, `276505630421`) or `caselaw-stg` (staging, `626206937213`). Verify with `aws sts get-caller-identity --profile <p>`; re-authenticate with `dalmatian aws login` if the SSO token has expired.
- Terraform workspace names: production `E276505630421-eu-west-2-caselaw-caselaw-prod`, staging `E626206937213-eu-west-2-caselaw-stg-caselaw-staging`. The leading `E` is part of the name, not a typo.
- Production `resource_prefix_hash` is `3d06b7b2`; staging's is `58785dac`. These are `format("%.8s", sha512(resource_prefix))` and must not be recomputed by hand.
- Scratch working directory for throwaway files: `/var/folders/px/85vvbg2966n8t9tk9zj45rfr0000gp/T/opencode`. Nothing outside the repo gets committed.

## File Structure

**`terraform-dxw-dalmatian-infrastructure` (branch `add-ssm-parameters-to-custom-cloudformation-stacks`):**

| File | Responsibility | Change |
| --- | --- | --- |
| `variables.tf` | Input contract and validation for `custom_cloudformation_stacks` | Add `ssm_parameters` to the object type, document it, add a conflicting-key validation, fix the stale `enable_cloudformatian_s3_template_store` description |
| `locals.tf` | Flatten `ssm_parameters` into a `for_each`-able map; produce the merged per-stack parameter map | Add two locals |
| `data.tf` | Resolve SSM parameter values | Add `data "aws_ssm_parameter" "custom_cloudformation_stack"` |
| `cloudformation-custom-stack.tf` | Create the stacks | Point `parameters` at the new local |

**Not in this repo:** the caselaw production tfvars live in the `<project-hash>-tfvars`
S3 bucket, cached locally at
`/Users/bob/.config/dalmatian/.cache/tfvars/200-E276505630421-eu-west-2-caselaw-caselaw-prod.tfvars`.
Tasks 4, 6 and 7 change that cached file directly rather than going through
`dalmatian terraform-dependencies set-tfvars`, because `set-tfvars` opens `$EDITOR`
and then runs a plan and an apply itself, which the human needs to drive. Two
consequences:

- The cached file is what `deploy infrastructure` reads, so a direct edit takes
  effect immediately for plans and applies.
- Nothing uploads the edit to S3 until
  `dalmatian deploy account-bootstrap -a 511700466171-eu-west-2-dalmatian-main -N`
  runs on the main account. That is Task 9. Until then the S3 copy is stale, and the
  next `set-tfvars` on this workspace will report "The remote file is different than
  your local cached copy" — the correct answer there is `1) Edit my local copy`.

None of this is version controlled, so Tasks 3 to 7 and 9 produce no commits.

**Scratch only:** `/var/folders/px/85vvbg2966n8t9tk9zj45rfr0000gp/T/opencode/ssm-params-harness/`
holds the Task 1 test harness (`.terraform-version`, `main.tf`, `valid.tfvars`,
`conflict.tfvars`). It is never committed. The harness has already been run while
writing this plan: the valid case produces the documented outputs and the conflict
case fails on the validation, and the HCL in Task 1 is `terraform fmt` clean.

---

### Task 1: `ssm_parameters` support in the infrastructure module

**Files:**
- Create: `/var/folders/px/85vvbg2966n8t9tk9zj45rfr0000gp/T/opencode/ssm-params-harness/.terraform-version` (scratch, not committed)
- Create: `/var/folders/px/85vvbg2966n8t9tk9zj45rfr0000gp/T/opencode/ssm-params-harness/main.tf` (scratch, not committed)
- Create: `/var/folders/px/85vvbg2966n8t9tk9zj45rfr0000gp/T/opencode/ssm-params-harness/valid.tfvars` (scratch)
- Create: `/var/folders/px/85vvbg2966n8t9tk9zj45rfr0000gp/T/opencode/ssm-params-harness/conflict.tfvars` (scratch)
- Modify: `variables.tf:975-1007`
- Modify: `locals.tf:282-290`
- Modify: `data.tf:110-121` (append after `data "external" "s3_presigned_url"`)
- Modify: `cloudformation-custom-stack.tf:1-10`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces:
  - tfvars contract: `custom_cloudformation_stacks.<stack>.ssm_parameters` is a `map(string)` of CloudFormation parameter name to SSM parameter name, defaulting to `{}`. Tasks 6 and 7 rely on this.
  - `local.custom_cloudformation_stack_ssm_parameters` — `map(string)` keyed `"<stack_key>:<param_key>"`, value = SSM parameter name.
  - `local.custom_cloudformation_stack_parameters` — `map(map(string))` keyed by stack key, value = complete CloudFormation parameter map.
  - `data.aws_ssm_parameter.custom_cloudformation_stack` — keyed identically to `local.custom_cloudformation_stack_ssm_parameters`.

The harness in steps 1 to 4 exists because the flattening and validation are pure
HCL and can be exercised in seconds without AWS credentials or a 20-minute plan
against a real workspace. `data.aws_ssm_parameter` is replaced in the harness by a
stub local, so the harness tests the logic that surrounds it, not the provider.

- [ ] **Step 1: Write the failing test harness** `[agent]`

The harness directory sits outside any repo, so `tfenv` falls back to an old default
(1.3.6 on this machine) and the `required_version` constraint fails. Pin it first:

```bash
mkdir -p /var/folders/px/85vvbg2966n8t9tk9zj45rfr0000gp/T/opencode/ssm-params-harness
printf '1.12.0\n' > /var/folders/px/85vvbg2966n8t9tk9zj45rfr0000gp/T/opencode/ssm-params-harness/.terraform-version
```

Create `/var/folders/px/85vvbg2966n8t9tk9zj45rfr0000gp/T/opencode/ssm-params-harness/main.tf`:

```hcl
terraform {
  required_version = ">= 1.12.0"
}

variable "custom_cloudformation_stacks" {
  type = map(object({
    s3_template_store_key = optional(string, null)
    template_body         = optional(string, null)
    parameters            = optional(map(string), null)
    ssm_parameters        = optional(map(string), {})
    on_failure            = optional(string, null)
    capabilities          = optional(list(string), null)
  }))

  validation {
    condition = alltrue([
      for k, v in var.custom_cloudformation_stacks : can(regex("^[a-zA-Z0-9-]+$", k))
    ])
    error_message = "CloudFormation stack names (keys in custom_cloudformation_stacks) can only contain alphanumeric characters and hyphens."
  }

  validation {
    condition = alltrue([
      for k, v in var.custom_cloudformation_stacks :
      length(setintersection(
        keys(coalesce(v["parameters"], {})),
        keys(v["ssm_parameters"])
      )) == 0
    ])
    error_message = "CloudFormation stack parameters cannot be set in both `parameters` and `ssm_parameters`."
  }
}

locals {
  custom_cloudformation_stacks = var.custom_cloudformation_stacks

  custom_cloudformation_stack_ssm_parameters = merge([
    for stack_key, stack in local.custom_cloudformation_stacks : {
      for param_key, ssm_name in stack["ssm_parameters"] :
      "${stack_key}:${param_key}" => ssm_name
    }
  ]...)

  # Stands in for data.aws_ssm_parameter.custom_cloudformation_stack[*].value,
  # so the harness exercises the flatten and merge without hitting AWS.
  stub_ssm_values = {
    for k, v in local.custom_cloudformation_stack_ssm_parameters :
    k => "resolved-value-for-${v}"
  }

  custom_cloudformation_stack_parameters = {
    for stack_key, stack in local.custom_cloudformation_stacks :
    stack_key => merge(
      coalesce(stack["parameters"], {}),
      {
        for param_key, ssm_name in stack["ssm_parameters"] :
        param_key => local.stub_ssm_values["${stack_key}:${param_key}"]
      }
    )
  }
}

output "ssm_parameter_keys" {
  value = local.custom_cloudformation_stack_ssm_parameters
}

output "stack_parameters" {
  value = local.custom_cloudformation_stack_parameters
}
```

Create `valid.tfvars` in the same directory — one stack using `ssm_parameters`, one
stack without, to prove the no-op path:

```hcl
custom_cloudformation_stacks = {
  with-secret = {
    parameters     = { AdminUser = "someone", InstanceType = "t3.small" }
    ssm_parameters = { AdminPass = "/example/path/ADMIN_PASSWORD" }
  }
  without-secret = {
    parameters = { AdminUser = "someone-else" }
  }
}
```

Create `conflict.tfvars` in the same directory — the same key in both maps:

```hcl
custom_cloudformation_stacks = {
  bad-stack = {
    parameters     = { AdminPass = "literal-value" }
    ssm_parameters = { AdminPass = "/example/path/ADMIN_PASSWORD" }
  }
}
```

- [ ] **Step 2: Run the harness to verify both cases behave correctly** [agent]

```bash
cd /var/folders/px/85vvbg2966n8t9tk9zj45rfr0000gp/T/opencode/ssm-params-harness
terraform version   # must report v1.12.0
terraform init -backend=false
terraform plan -var-file=valid.tfvars
terraform plan -var-file=conflict.tfvars
```

Expected for `valid.tfvars`: exits 0, and the outputs show

```
  + ssm_parameter_keys = {
      + "with-secret:AdminPass" = "/example/path/ADMIN_PASSWORD"
    }
  + stack_parameters   = {
      + with-secret    = {
          + AdminPass    = "resolved-value-for-/example/path/ADMIN_PASSWORD"
          + AdminUser    = "someone"
          + InstanceType = "t3.small"
        }
      + without-secret = {
          + AdminUser = "someone-else"
        }
    }
```

The two things to confirm: `without-secret` gets an empty `ssm_parameters` default
and its parameter map is untouched, and the flattened key uses the `stack:param`
form.

Expected for `conflict.tfvars`: exits 1 with

```
CloudFormation stack parameters cannot be set in both `parameters` and
`ssm_parameters`.

This was checked by the validation rule at main.tf:22,3-13.
```

If the conflict case passes, the validation is wrong — fix it before continuing.

- [ ] **Step 3: Add `ssm_parameters` to the variable** [agent]

In `variables.tf`, replace the whole `variable "custom_cloudformation_stacks"` block
(currently lines 980-1007) with:

```hcl
variable "custom_cloudformation_stacks" {
  description = <<EOT
    Map of CloudFormation stacks to deploy
    {
      stack-name = {
        s3_template_store_key: The filename of a CloudFormation template that is stored within the S3 bucket, created by the `enable_cloudformatian_s3_template_store`
        template_body: (Optional - use of s3_template_store_key is preferred) The CloudFormation template body
        parameters: The CloudFormation template parameters ({ parameter-name = parameter-value, ... })
        ssm_parameters: CloudFormation template parameters whose values are read from AWS SSM Parameter Store ({ parameter-name = ssm-parameter-name, ... }). Use this for secrets, so that they are not stored in plaintext in tfvars. The SSM parameter must already exist, otherwise the plan will fail. SecureString parameters are decrypted automatically. Note that a stack using `ssm_parameters` has its whole parameter map marked as sensitive, so it renders as "(sensitive value)" in plan output
        on_failure: What to do on failure, either 'DO_NOTHING', 'ROLLBACK' or 'DELETE'
        capabilities: A list of capabilities. Valid values: `CAPABILITY_NAMED_IAM`, `CAPABILITY_IAM`, `CAPABILITY_AUTO_EXPAND`
      }
    }
  EOT
  type = map(object({
    s3_template_store_key = optional(string, null)
    template_body         = optional(string, null)
    parameters            = optional(map(string), null)
    ssm_parameters        = optional(map(string), {})
    on_failure            = optional(string, null)
    capabilities          = optional(list(string), null)
  }))

  validation {
    condition = alltrue([
      for k, v in var.custom_cloudformation_stacks : can(regex("^[a-zA-Z0-9-]+$", k))
    ])
    error_message = "CloudFormation stack names (keys in custom_cloudformation_stacks) can only contain alphanumeric characters and hyphens."
  }

  validation {
    condition = alltrue([
      for k, v in var.custom_cloudformation_stacks :
      length(setintersection(
        keys(coalesce(v["parameters"], {})),
        keys(v["ssm_parameters"])
      )) == 0
    ])
    error_message = "CloudFormation stack parameters cannot be set in both `parameters` and `ssm_parameters`."
  }
}
```

While in this file, fix the stale claim in the neighbouring variable at line 976.
No such IAM user is created anywhere in
`cloudformation-custom-stack-s3-template-store.tf`. Replace:

```hcl
  description = "Creates an S3 bucket to store custom CloudFormation templates, which can then be referenced in `custom_cloudformation_stacks`. A user with RW access to the bucket is also created."
```

with:

```hcl
  description = "Creates an S3 bucket to store custom CloudFormation templates, which can then be referenced in `custom_cloudformation_stacks`."
```

- [ ] **Step 4: Add the locals** [agent]

In `locals.tf`, after the `s3_object_presign` local (currently ends at line 290),
insert:

```hcl
  custom_cloudformation_stack_ssm_parameters = merge([
    for stack_key, stack in local.custom_cloudformation_stacks : {
      for param_key, ssm_name in stack["ssm_parameters"] :
      "${stack_key}:${param_key}" => ssm_name
    }
  ]...)

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

`merge([]...)` returns `{}`, so no stacks and no `ssm_parameters` are both safe.

- [ ] **Step 5: Add the data source** [agent]

In `data.tf`, after the closing brace of `data "external" "s3_presigned_url"`
(currently line 121), append:

```hcl
data "aws_ssm_parameter" "custom_cloudformation_stack" {
  for_each = local.custom_cloudformation_stack_ssm_parameters

  name = each.value
}
```

No `with_decryption` argument: it defaults to `true`, so `SecureString` values are
decrypted.

- [ ] **Step 6: Wire the merged parameters into the stack resource** [agent]

In `cloudformation-custom-stack.tf`, change the `parameters` line only:

```hcl
  parameters        = local.custom_cloudformation_stack_parameters[each.key]
```

Leave `name`, `template_body`, `template_url`, `on_failure`, `notification_arns` and
`capabilities` exactly as they are.

- [ ] **Step 7: Run the repo's checks** [agent]

```bash
cd /Users/bob/git/dxw/terraform-dxw-dalmatian-infrastructure
tfenv use 1.12.0
terraform fmt -check -diff
terraform init -backend=false
terraform validate
tflint -f compact
```

Expected: `terraform fmt -check -diff` prints nothing and exits 0, `terraform
validate` prints `Success! The configuration is valid.`, `tflint` reports no new
issues. If `fmt -check` flags the files you touched, run `terraform fmt` on them
and re-check.

- [ ] **Step 8: Commit** [agent, ask the user first]

```bash
cd /Users/bob/git/dxw/terraform-dxw-dalmatian-infrastructure
git add variables.tf locals.tf data.tf cloudformation-custom-stack.tf
git status --short
git commit -F - <<'EOF'
Allow CloudFormation parameters to be read from SSM

Stack parameters could only be set as literal strings in tfvars, which
meant secrets such as the MarkLogic administrator password were readable
by anyone with access to the tfvars bucket.

Add an optional ssm_parameters map to each stack, resolved through
data.aws_ssm_parameter and merged over the literal parameters. Setting a
parameter in both maps is rejected by a validation, so precedence is
never ambiguous. CloudFormation cannot resolve these itself: ssm-secure
dynamic references are only honoured in an allowlist of resource
properties which excludes instance UserData, and the
AWS::SSM::Parameter::Value<String> parameter type resolves plaintext
parameters only.

Stacks that do not use ssm_parameters produce an identical parameter map
and are unaffected.
EOF
git log --oneline -2
```

Confirm `git status --short` shows only the four expected files staged, with the
four pre-existing untracked files still untracked.

---

### Task 2: Prove no regression against caselaw staging

Staging has the only two `custom_cloudformation_stacks` in the estate. If they plan
clean on the branch, the change is a no-op for every existing consumer. This must
pass before production is touched.

**Files:** none modified. This task only reads.

**Interfaces:**
- Consumes: the branch from Task 1.
- Produces: confidence that Tasks 4 to 7 can proceed; no artifacts.

- [ ] **Step 1: Push the branch** [human]

```bash
cd /Users/bob/git/dxw/terraform-dxw-dalmatian-infrastructure
git push -u origin add-ssm-parameters-to-custom-cloudformation-stacks
```

`terraform-dependencies clone` fetches from GitHub, not from the local working copy,
so an unpushed commit is invisible to the next step.

- [ ] **Step 2: Point the dalmatian CLI at the branch** [human]

```bash
~/bin/update-dalmatian-infrastructure-module.sh
```

That script runs `dalmatian version -v 2` then
`dalmatian terraform-dependencies clone -i "$(git branch --show-current)" -I` from
the repo directory, cloning the branch into
`/Users/bob/git/dxw/dalmatian-tools/tmp/terraform-dxw-dalmatian-infrastructure` and
initialising it. Re-run this after any further push.

- [ ] **Step 3: Verify the clone is on the right commit** [agent]

```bash
git -C /Users/bob/git/dxw/dalmatian-tools/tmp/terraform-dxw-dalmatian-infrastructure log --oneline -1
grep -c "custom_cloudformation_stack_ssm_parameters" /Users/bob/git/dxw/dalmatian-tools/tmp/terraform-dxw-dalmatian-infrastructure/locals.tf
```

Expected: the commit from Task 1 step 8, and a count of `1` (the local's definition;
the only other reference lives in `data.tf`). If the count is `0`, the clone predates
the push — re-run step 2.

- [ ] **Step 4: Plan against staging on the branch, and on main, and compare** `[agent]`

Staging has a pre-existing perpetual diff on both MarkLogic stacks, so "no changes"
is the wrong criterion. The question this step answers is narrower and stricter: does
the branch produce *the same* diff as `main`? Capture both and compare the change
blocks, ignoring the refresh log, whose ordering is non-deterministic.

```bash
cd /Users/bob/git/dxw/dalmatian-tools
SCRATCH=/var/folders/px/85vvbg2966n8t9tk9zj45rfr0000gp/T/opencode

# Branch (the clone is already on it from step 2)
DALMATIAN_SKIP_UPDATE_CHECK=1 ./bin/dalmatian deploy infrastructure \
  -w E626206937213-eu-west-2-caselaw-stg-caselaw-staging -p > "$SCRATCH/plan-branch.txt" 2>&1

# main
DALMATIAN_SKIP_UPDATE_CHECK=1 ./bin/dalmatian terraform-dependencies clone -i main -I
DALMATIAN_SKIP_UPDATE_CHECK=1 ./bin/dalmatian deploy infrastructure \
  -w E626206937213-eu-west-2-caselaw-stg-caselaw-staging -p > "$SCRATCH/plan-main.txt" 2>&1

# Compare only the change blocks
for f in plan-branch plan-main; do
  sed -e 's/\x1b\[[0-9;]*m//g' "$SCRATCH/$f.txt" > "$SCRATCH/$f.clean.txt"
  awk '/Terraform will perform the following actions/,/^Plan: /' "$SCRATCH/$f.clean.txt" > "$SCRATCH/$f.changes.txt"
done
diff "$SCRATCH/plan-main.changes.txt" "$SCRATCH/plan-branch.changes.txt"; echo "diff-exit=$?"

# Put the clone back on the branch
DALMATIAN_SKIP_UPDATE_CHECK=1 ./bin/dalmatian terraform-dependencies clone \
  -i add-ssm-parameters-to-custom-cloudformation-stacks -I
```

Expected: `diff-exit=0`, and both plans report
`Plan: 0 to add, 2 to change, 0 to destroy.` with the only differences inside the two
MarkLogic stacks being `parameters["AdminPass"]` going `"****" -> "<literal>"`,
`template_url` as `(sensitive value)`, and `outputs` going to `(known after apply)`.
All 26 and 29 other parameters respectively must show as unchanged.

Any difference between the two change blocks is a defect in Task 1 — most likely
`coalesce` on a null `parameters` altering the map. Do not proceed to Task 3 until
`diff-exit=0`. Unrelated drift from other people's changes should be reported to the
user rather than applied.

Finally, confirm the clone is back on `c76642d` before continuing, or every later
plan silently runs against `main`.

---

### Task 3: Create the production administrator password in SSM

**Files:** none. This creates an out-of-band AWS resource that Task 6 reads.

**Interfaces:**
- Consumes: nothing.
- Produces: SSM `SecureString` at `/caselaw/marklogic-202608/prod/ADMIN_PASSWORD` in
  account `276505630421`, region `eu-west-2`. Task 6 references this exact path.

- [ ] **Step 1: Confirm the parameter does not already exist** [agent]

```bash
export AWS_CONFIG_FILE=~/.config/dalmatian/dalmatian-sso.config
aws sts get-caller-identity --profile caselaw
aws ssm get-parameter --profile caselaw --region eu-west-2 \
  --name /caselaw/marklogic-202608/prod/ADMIN_PASSWORD 2>&1
```

Expected: `get-caller-identity` shows account `276505630421`, and `get-parameter`
fails with `ParameterNotFound`. If it already exists, stop and ask the user before
overwriting anything.

- [ ] **Step 2: Generate and store the password** [human]

The template's `AllowedPattern` on `AdminPass` is `^(?!.*[*]).*$`, so asterisks are
rejected. Use 32 alphanumeric characters, matching what the staging cluster uses:

```bash
export AWS_CONFIG_FILE=~/.config/dalmatian/dalmatian-sso.config
ML_ADMIN_PASS="$(LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 32)"
echo "${#ML_ADMIN_PASS}"
aws ssm put-parameter \
  --profile caselaw \
  --region eu-west-2 \
  --name /caselaw/marklogic-202608/prod/ADMIN_PASSWORD \
  --description "MarkLogic administrator password for the cf-3d06b7b2-marklogic-202608 cluster" \
  --type SecureString \
  --value "$ML_ADMIN_PASS"
echo "$ML_ADMIN_PASS"
```

Expected: `32`, then `{"Version": 1, "Tier": "Standard"}`. Give the final echoed
value to the user for the team password store, then `unset ML_ADMIN_PASS`.

- [ ] **Step 3: Verify it reads back** [agent]

```bash
export AWS_CONFIG_FILE=~/.config/dalmatian/dalmatian-sso.config
aws ssm get-parameter --profile caselaw --region eu-west-2 \
  --name /caselaw/marklogic-202608/prod/ADMIN_PASSWORD \
  --with-decryption --query 'Parameter.{Type:Type,Len:Value}' --output json \
  | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['Type'], len(d['Len']))"
```

Expected: `SecureString 32`.

No commit: nothing in the repo changed.

---

### Task 4: Enable the production CloudFormation template store

**Files:**
- Modify: `/Users/bob/.config/dalmatian/.cache/tfvars/200-E276505630421-eu-west-2-caselaw-caselaw-prod.tfvars`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: S3 bucket `3d06b7b2-cloudformation-custom-stack-templates` in account
  `276505630421`. Task 5 uploads to it and Task 6 reads from it.

- [ ] **Step 1: Add the flag to the production tfvars** `[agent]`

Append to
`/Users/bob/.config/dalmatian/.cache/tfvars/200-E276505630421-eu-west-2-caselaw-caselaw-prod.tfvars`:

```hcl

# MarkLogic Clusters
enable_cloudformatian_s3_template_store = true
```

The variable name is misspelled in the module (`cloudformatian`). Copy it exactly.

- [ ] **Step 2: Plan** `[human]`

```bash
cd /Users/bob/git/dxw/dalmatian-tools
DALMATIAN_SKIP_UPDATE_CHECK=1 ./bin/dalmatian deploy infrastructure -w E276505630421-eu-west-2-caselaw-caselaw-prod -p
```

Expected: roughly six resources to add, all named
`cloudformation_custom_stack_template_store` — `aws_s3_bucket`,
`aws_s3_bucket_policy`, `aws_s3_bucket_public_access_block`,
`aws_s3_bucket_versioning`, `aws_s3_bucket_logging` and
`aws_s3_bucket_server_side_encryption_configuration`. No changes to existing
resources, and no destroys.

- [ ] **Step 3: Apply** `[human]`

```bash
cd /Users/bob/git/dxw/dalmatian-tools
DALMATIAN_SKIP_UPDATE_CHECK=1 ./bin/dalmatian deploy infrastructure -w E276505630421-eu-west-2-caselaw-caselaw-prod
```

Expected: `Apply complete! Resources: 6 added, 0 changed, 0 destroyed.`

- [ ] **Step 4: Verify the bucket exists** `[agent]`

```bash
export AWS_CONFIG_FILE=~/.config/dalmatian/dalmatian-sso.config
aws s3api head-bucket --profile caselaw --bucket 3d06b7b2-cloudformation-custom-stack-templates && echo BUCKET_OK
```

Expected: `BUCKET_OK`.

No commit: tfvars are not version controlled. The edit is local only until Task 9.

---

### Task 5: Copy the MarkLogic 11.3.6 template into the production bucket

The module presigns the template object at plan time. If the object is missing, the
plan still succeeds but CloudFormation fails on a 404, leaving a rolled-back stack.
So this must happen before Task 6.

**Files:**
- Create: `s3://3d06b7b2-cloudformation-custom-stack-templates/11/mlcluster.11.3.6.template`
- Create: `/var/folders/px/85vvbg2966n8t9tk9zj45rfr0000gp/T/opencode/ml/mlcluster.11.3.6.template` (scratch staging post)

**Interfaces:**
- Consumes: the bucket from Task 4.
- Produces: the object at key `11/mlcluster.11.3.6.template`, which Task 6 names in
  `s3_template_store_key`.

- [ ] **Step 1: Download from staging and upload to production** [human]

The accounts differ, so a server-side `aws s3 cp` between them is not available with
these credentials.

```bash
export AWS_CONFIG_FILE=~/.config/dalmatian/dalmatian-sso.config
mkdir -p /var/folders/px/85vvbg2966n8t9tk9zj45rfr0000gp/T/opencode/ml
aws s3 cp --profile caselaw-stg \
  s3://58785dac-cloudformation-custom-stack-templates/11/mlcluster.11.3.6.template \
  /var/folders/px/85vvbg2966n8t9tk9zj45rfr0000gp/T/opencode/ml/mlcluster.11.3.6.template
aws s3 cp --profile caselaw \
  /var/folders/px/85vvbg2966n8t9tk9zj45rfr0000gp/T/opencode/ml/mlcluster.11.3.6.template \
  s3://3d06b7b2-cloudformation-custom-stack-templates/11/mlcluster.11.3.6.template
```

- [ ] **Step 2: Verify the copy is byte-identical** [agent]

```bash
export AWS_CONFIG_FILE=~/.config/dalmatian/dalmatian-sso.config
cd /var/folders/px/85vvbg2966n8t9tk9zj45rfr0000gp/T/opencode/ml
shasum -a 256 mlcluster.11.3.6.template
aws s3 cp --profile caselaw \
  s3://3d06b7b2-cloudformation-custom-stack-templates/11/mlcluster.11.3.6.template \
  ./roundtrip.template
shasum -a 256 roundtrip.template
grep -m1 'version:' mlcluster.11.3.6.template
```

Expected: both checksums match, size is 43902 bytes, and the metadata line reads
`  version: 11.3.6`. If the version line says anything else, the wrong object was
copied — stop.

No commit.

---

### Task 6: Deploy the production MarkLogic cluster

**Files:**
- Modify: `/Users/bob/.config/dalmatian/.cache/tfvars/200-E276505630421-eu-west-2-caselaw-caselaw-prod.tfvars`

**Interfaces:**
- Consumes: `ssm_parameters` from Task 1, the SSM parameter from Task 3, the bucket
  from Task 4, the template object from Task 5.
- Produces: CloudFormation stack `cf-3d06b7b2-marklogic-202608` with child stacks
  `...-ManagedEniStack-*` and `...-NodeMgrLambdaStack-*`, and a new
  `InternalElbSecurityGroup` whose id Task 7 needs.

Every parameter value below is either copied from the existing
`caselaw-prod-marklogic-11` stack or is a deliberate, noted change. Two traps: the
old stack's `ECSSecurityGroup` value `sg-0e78026d5e85d721c` no longer exists and
must not be carried forward, and `ClusterName`, `PublicLoadBalancer` and
`InternalLoadBalancer` exist only in the MarkLogic 12 template, so passing any of
them to this template fails the stack.

- [ ] **Step 1: Retrieve the license key from the existing stack** [agent]

```bash
export AWS_CONFIG_FILE=~/.config/dalmatian/dalmatian-sso.config
aws cloudformation describe-stacks --profile caselaw --region eu-west-2 \
  --stack-name caselaw-prod-marklogic-11 \
  --query 'Stacks[0].Parameters[?ParameterKey==`LicenseKey`].ParameterValue' --output text
```

Expected: a `DF43-...-5000` style key. Use the exact output in the next step.

- [ ] **Step 2: Add the stack to the production tfvars** `[agent]`

Append to
`/Users/bob/.config/dalmatian/.cache/tfvars/200-E276505630421-eu-west-2-caselaw-caselaw-prod.tfvars`,
below the `enable_cloudformatian_s3_template_store` line added in Task 4,
substituting the license key from step 1:

```hcl
custom_cloudformation_stacks = {
  marklogic-202608 = {
    s3_template_store_key = "11/mlcluster.11.3.6.template"
    on_failure            = "DO_NOTHING"
    capabilities          = ["CAPABILITY_NAMED_IAM", "CAPABILITY_IAM", "CAPABILITY_AUTO_EXPAND"]
    parameters = {
      # Resource Configuration
      IAMRole             = "marklogic-cloudformation"
      VolumeSize          = "500"
      VolumeType          = "gp3"
      VolumeIOPS          = "3000"
      VolumeThroughput    = "125"
      VolumeEncryption    = "enable"
      VolumeEncryptionKey = ""
      InstanceType        = "t3.xlarge"
      SpotPrice           = "0"
      KeyName             = "marklogic-cloudformation"
      NumberOfZones       = "3"
      NodesPerZone        = "1"
      AZ                  = "eu-west-2a,eu-west-2b,eu-west-2c"
      LogSNS              = "none"

      # Network Configuration
      VPC                  = "vpc-0df87826529c1d490"
      PublicSubnet1        = "subnet-03d716daeffebfe12"
      PublicSubnet2        = "subnet-0bf8172d07a5c6d51"
      PublicSubnet3        = "subnet-0ed788c7e63c6f5aa"
      PrivateSubnet1       = "subnet-0fa90cd0842cba29a"
      PrivateSubnet2       = "subnet-077995ea5555c8132"
      PrivateSubnet3       = "subnet-04429c77f3048ad49"
      ExternalAccessCidrIP = "54.76.254.148/32"
      ECSSecurityGroup     = "sg-05f0edaea0288d3c5"

      # MarkLogic Configuration
      AdminUser  = "caselaw-prod-marklogic"
      Licensee   = "The National Archives - Unrestricted"
      LicenseKey = "<license key from step 1>"
    }
    ssm_parameters = {
      AdminPass = "/caselaw/marklogic-202608/prod/ADMIN_PASSWORD"
    }
  }
}
```

- [ ] **Step 3: Review the plan** `[human runs, agent reviews the output]`

```bash
cd /Users/bob/git/dxw/dalmatian-tools
DALMATIAN_SKIP_UPDATE_CHECK=1 ./bin/dalmatian deploy infrastructure -w E276505630421-eu-west-2-caselaw-caselaw-prod -p
```

Expected: exactly one resource added,
`aws_cloudformation_stack.custom["marklogic-202608"]`. Its `parameters` attribute
renders as `(sensitive value)` — that is the intended consequence of merging a
sensitive SSM value, not an error. `data.aws_ssm_parameter.custom_cloudformation_stack`
is read during the plan; a `ParameterNotFound` here means Task 3 was skipped or the
path is wrong.

Because the map is sensitive, the ~26 parameter values cannot be reviewed in the plan
output. To check them before applying, print the resolved map with the secret elided:

```bash
cd /Users/bob/git/dxw/dalmatian-tools/tmp/terraform-dxw-dalmatian-infrastructure
terraform workspace show   # must be E276505630421-eu-west-2-caselaw-caselaw-prod
terraform console -var-file=... <<'EOF'
nonsensitive({ for k, v in local.custom_cloudformation_stack_parameters["marklogic-202608"] : k => k == "AdminPass" ? "<redacted>" : v })
EOF
```

`terraform console` needs the same `-var-file` chain that
`run-terraform-command` passes; read them from
`/Users/bob/git/dxw/dalmatian-tools/bin/terraform-dependencies/v2/run-terraform-command`.
Simpler alternative: read the tfvars block back, since every value except `AdminPass`
is a literal there.

Nothing else should change. Any proposed change to an existing resource, and
especially any destroy, means stop and investigate.

- [ ] **Step 4: Apply** `[human]`

```bash
cd /Users/bob/git/dxw/dalmatian-tools
DALMATIAN_SKIP_UPDATE_CHECK=1 ./bin/dalmatian deploy infrastructure -w E276505630421-eu-west-2-caselaw-caselaw-prod
```

Expected: `Apply complete! Resources: 1 added, 0 changed, 0 destroyed.` after roughly
20 to 30 minutes. The nested ManagedEni and NodeMgrLambda stacks are created by
CloudFormation, not Terraform, so they will not appear in the plan.

From this point on, **every subsequent caselaw production plan will show
`aws_cloudformation_stack.custom["marklogic-202608"]` updating in place**, for the
same two reasons staging does: `NoEcho` masks `AdminPass` to `****` in state, and the
presigned `template_url` is regenerated each plan. Applying it is benign — staging
applied exactly this on 2026-08-18 13:03 and it completed in 14 seconds, updating
only the two nested stacks, with no ASG, LaunchConfiguration or EC2 events and no node
replacement. It is noise, not damage, but it is permanent noise and worth a follow-up
ticket.

If the stack fails, `on_failure = "DO_NOTHING"` leaves it in place for inspection:

```bash
export AWS_CONFIG_FILE=~/.config/dalmatian/dalmatian-sso.config
aws cloudformation describe-stack-events --profile caselaw --region eu-west-2 \
  --stack-name cf-3d06b7b2-marklogic-202608 \
  --query 'StackEvents[?ResourceStatus==`CREATE_FAILED`].[LogicalResourceId,ResourceStatusReason]' \
  --output table
```

- [ ] **Step 5: Verify the cluster** `[agent]`

```bash
export AWS_CONFIG_FILE=~/.config/dalmatian/dalmatian-sso.config
aws cloudformation describe-stacks --profile caselaw --region eu-west-2 \
  --stack-name cf-3d06b7b2-marklogic-202608 \
  --query 'Stacks[0].{Status:StackStatus,URL:Outputs[?OutputKey==`URL`].OutputValue|[0]}' \
  --output json
aws autoscaling describe-auto-scaling-groups --profile caselaw --region eu-west-2 \
  --query 'AutoScalingGroups[?contains(AutoScalingGroupName,`marklogic-202608`)].{Name:AutoScalingGroupName,Desired:DesiredCapacity,InService:length(Instances[?LifecycleState==`InService`])}' \
  --output table
```

Expected: `CREATE_COMPLETE`, a `URL` output, and three ASGs each with one in-service
instance. The load balancer is internal, so reaching port 8001 and logging in as
`caselaw-prod-marklogic` with the Task 3 password requires being on the dxw VPN or
tunnelling through the bastion. Report the URL to the user and ask them to confirm
the admin login if you cannot reach it yourself.

No commit.

---

### Task 7: Allow the ECS cluster to reach the new MarkLogic cluster

The template creates an `InternalElbSecurityGroup` with ingress from the ECS
container instances security group, but the ECS side needs matching egress. That
security group does not exist until Task 6 completes, hence a separate apply.

**Files:**
- Modify: `/Users/bob/.config/dalmatian/.cache/tfvars/200-E276505630421-eu-west-2-caselaw-caselaw-prod.tfvars`

**Interfaces:**
- Consumes: the `InternalElbSecurityGroup` created in Task 6.
- Produces: two egress rules on the ECS container instances security group.

- [ ] **Step 1: Find the new internal ELB security group id** [agent]

```bash
export AWS_CONFIG_FILE=~/.config/dalmatian/dalmatian-sso.config
aws cloudformation describe-stack-resources --profile caselaw --region eu-west-2 \
  --stack-name cf-3d06b7b2-marklogic-202608 \
  --query 'StackResources[?LogicalResourceId==`InternalElbSecurityGroup`].PhysicalResourceId' \
  --output text
```

Expected: a single `sg-...` id. It must differ from `sg-0a411fd600e4cce26`, which
belongs to the 2023 cluster.

- [ ] **Step 2: Add the egress rules** `[agent]`

In
`/Users/bob/.config/dalmatian/.cache/tfvars/200-E276505630421-eu-west-2-caselaw-caselaw-prod.tfvars`,
inside the existing `infrastructure_ecs_cluster_custom_security_group_rules` map,
alongside the existing `mark-logic-egress-1` and `mark-logic-egress-2` entries which
stay untouched so the old cluster keeps serving, add:

```hcl
  mark-logic-202608-egress-1 = {
    description              = "Allow Egress to Mark Logic 202608"
    type                     = "egress"
    from_port                = 8000
    to_port                  = 8011
    protocol                 = "tcp"
    source_security_group_id = "<sg id from step 1>"
  }
  mark-logic-202608-egress-2 = {
    description              = "Allow Egress to Mark Logic 202608"
    type                     = "egress"
    from_port                = 7997
    to_port                  = 7998
    protocol                 = "tcp"
    source_security_group_id = "<sg id from step 1>"
  }
```

The port ranges mirror the ingress the template puts on
`InternalElbSecurityGroup`: 7997 to 7998 and 8000 to 8011.

- [ ] **Step 3: Review the plan and apply** `[human]`

Expected: two `aws_security_group_rule` resources added, plus
`aws_cloudformation_stack.custom["marklogic-202608"]` updating in place. That stack
update is the known perpetual diff described at the end of Task 6, not a regression.
Nothing destroyed, and in particular the existing `mark-logic-egress-1` and `-2` rules
must not appear as changing.

```bash
cd /Users/bob/git/dxw/dalmatian-tools
DALMATIAN_SKIP_UPDATE_CHECK=1 ./bin/dalmatian deploy infrastructure -w E276505630421-eu-west-2-caselaw-caselaw-prod
```

Expected: `Apply complete! Resources: 2 added, 1 changed, 0 destroyed.`

- [ ] **Step 4: Verify the rules landed** `[agent]`

```bash
export AWS_CONFIG_FILE=~/.config/dalmatian/dalmatian-sso.config
aws ec2 describe-security-group-rules --profile caselaw --region eu-west-2 \
  --filters Name=group-id,Values=sg-05f0edaea0288d3c5 \
  --query 'SecurityGroupRules[?IsEgress==`true` && contains(Description,`202608`)].{From:FromPort,To:ToPort,Dest:ReferencedGroupInfo.GroupId}' \
  --output table
```

Expected: two rows, 8000 to 8011 and 7997 to 7998, both referencing the step 1
security group id.

No commit.

---

### Task 8: Open the pull request

**Files:** none modified.

**Interfaces:**
- Consumes: the branch from Tasks 1 and 2, validated in production by Tasks 4 to 7.
- Produces: a PR URL.

- [ ] **Step 1: Review the full branch diff** [agent]

```bash
cd /Users/bob/git/dxw/terraform-dxw-dalmatian-infrastructure
git fetch origin
git diff origin/main...HEAD --stat
git log --oneline origin/main..HEAD
```

Expected: two commits (the design doc and the module change) touching five files.
Nothing else.

- [ ] **Step 2: Ask the user before opening the PR** [human]

Do not run `gh pr create` without explicit approval. When approved:

```bash
cd /Users/bob/git/dxw/terraform-dxw-dalmatian-infrastructure
gh pr create \
  --title "Allow CloudFormation stack parameters to be read from SSM" \
  --body "$(cat <<'EOF'
## What

Adds an optional `ssm_parameters` map to `custom_cloudformation_stacks`, so a
stack parameter's value can be read from SSM Parameter Store instead of being
written as a literal string in tfvars.

## Why

MarkLogic administrator passwords were being passed to CloudFormation as
plaintext tfvars values, readable by anyone with access to the tfvars bucket.
CloudFormation cannot resolve these itself: `ssm-secure` dynamic references are
only honoured in an allowlist of resource properties which excludes instance
UserData, and `AWS::SSM::Parameter::Value<String>` resolves plaintext parameters
only. So Terraform resolves the value and passes it through as an ordinary stack
parameter.

Setting a parameter in both `parameters` and `ssm_parameters` is rejected by a
variable validation.

## Notes

- Stacks that do not use `ssm_parameters` produce an identical parameter map.
  Verified by a `terraform plan` against caselaw staging, which holds the only
  two `custom_cloudformation_stacks` in the estate: no changes.
- A stack that does use `ssm_parameters` has its whole `parameters` map marked
  sensitive by the provider, so it renders as `(sensitive value)` in plans. This
  is per resource instance, so other stacks are unaffected. The resource already
  does the same for `template_url`.
- Also drops a stale sentence from the
  `enable_cloudformatian_s3_template_store` description claiming an IAM user is
  created for the bucket. No such user exists in the code.
- Design doc: `docs/superpowers/specs/2026-08-19-marklogic-prod-cluster-ssm-secrets-design.md`
- Used in anger to deploy `cf-3d06b7b2-marklogic-202608`, a MarkLogic 11.3.6
  cluster in caselaw production.
EOF
)"
```

- [ ] **Step 3: Check CI** [agent]

```bash
cd /Users/bob/git/dxw/terraform-dxw-dalmatian-infrastructure
gh pr checks --watch
```

Expected: `Terraform Validate` and `tflint` both pass. Report the PR URL to the user.

---

### Task 9: Upload the edited tfvars to S3

Tasks 4, 6 and 7 edited only the local cache. `set-tfvars` would normally push it,
by running account-bootstrap on the main Dalmatian account after a successful
deploy. Since the edits bypassed `set-tfvars`, that has to be done explicitly, or
the next person to touch this workspace gets a stale remote copy.

**Files:** none. This uploads
`200-E276505630421-eu-west-2-caselaw-caselaw-prod.tfvars` to the tfvars bucket.

**Interfaces:**
- Consumes: the completed tfvars edits from Tasks 4, 6 and 7.
- Produces: local and remote tfvars in agreement.

- [ ] **Step 1: Confirm local and remote currently differ** `[agent]`

```bash
export AWS_CONFIG_FILE=~/.config/dalmatian/dalmatian-sso.config
# 52a713-tfvars is "$(printf 'dxw-dalmatian' | shasum | head -c 6)-tfvars", the
# project-name hash the dalmatian CLI derives the bucket name from.
aws s3 cp --profile dalmatian-main \
  "s3://52a713-tfvars/200-E276505630421-eu-west-2-caselaw-caselaw-prod.tfvars" \
  /var/folders/px/85vvbg2966n8t9tk9zj45rfr0000gp/T/opencode/remote-prod.tfvars
diff /var/folders/px/85vvbg2966n8t9tk9zj45rfr0000gp/T/opencode/remote-prod.tfvars \
  /Users/bob/.config/dalmatian/.cache/tfvars/200-E276505630421-eu-west-2-caselaw-caselaw-prod.tfvars
```

Expected: the diff shows exactly the MarkLogic additions from Tasks 4, 6 and 7 and
nothing else. Anything else in the diff means someone changed the remote copy
meanwhile — stop and reconcile with the user before uploading.

- [ ] **Step 2: Run account-bootstrap on the main account** `[human]`

```bash
cd /Users/bob/git/dxw/dalmatian-tools
DALMATIAN_SKIP_UPDATE_CHECK=1 ./bin/dalmatian deploy account-bootstrap -a 511700466171-eu-west-2-dalmatian-main
```

Expected: the only changes are to the tfvars S3 objects. Review before approving.

- [ ] **Step 3: Confirm local and remote now match** `[agent]`

Re-run the step 1 commands. Expected: `diff` produces no output and exits 0.

No commit.

---

## Follow-up work, not in this plan

Raise these separately:

- Migrate data from `caselaw-prod-marklogic-11` to `cf-3d06b7b2-marklogic-202608`.
- Cut applications over: `/caselaw/editor/prod/MARKLOGIC_*` and
  `/caselaw/priv-api/prod/MARKLOGIC_*` still point at the old cluster.
- Decommission `caselaw-prod-marklogic-11` and its two child stacks.
- Configure backups for the new cluster, including the
  `tna-caselaw-marklogic-backup` bucket and its Azure sync job.
- Move staging's two plaintext `AdminPass` values to `ssm_parameters`.
- Deal with the perpetual diff on every `custom_cloudformation_stacks` stack. `NoEcho`
  parameters refresh to `****`, and the presigned `template_url` is regenerated on
  every plan, so these stacks are never converged and every apply issues a
  CloudFormation stack update. `ignore_changes` cannot express this, because it takes
  only static attribute references and the parameter names come from a variable.
  Options worth exploring: a stable `template_url` (versioned object URL rather than a
  presign), or moving the presign into the resource's `lifecycle`-exempt path.
- Tighten the `marklogic-cloudformation` instance profile. It has `IAMFullAccess`
  plus eight other `*FullAccess` managed policies attached, which is a privilege
  escalation path from any node in the cluster.
- Cut a `terraform-dxw-dalmatian-infrastructure` release and bump
  `terraform-project-versions.json` in dalmatian-tools, so the estate is not
  relying on a branch clone.
