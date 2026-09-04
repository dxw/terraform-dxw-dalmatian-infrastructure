# 1. Platform-managed Cognito user pools

Date: 2026-09-03

## Status

Accepted

## Context

An application moving onto Dalmatian v2 authenticates against an Amazon
Cognito user pool that lives in a client-owned AWS account. Cognito pools
cannot move between accounts or regions, and password hashes cannot be
exported. The platform had no Cognito support; the alternatives were
cross-account use of the existing pool (Cognito has no resource policies,
so every admin call would need an assumed role), onboarding the client
account as an external Dalmatian account, a CloudFormation template
through the custom stack hook, or first-class Terraform.

## Decision

Cognito user pools are a first-class, optional Dalmatian v2 feature declared
in `infrastructure_cognito_user_pools`. Services opt into admin access with
`cognito_user_pools`, which attaches a policy scoped to those pool ARNs to
the task role. Pool ID, client ID and client secret are read from Cognito
with `dalmatian cognito show-client` and pasted by the operator into the
service's existing S3 environment file.
Users are moved with a Cognito bulk import job (`dalmatian cognito
import-users`); every imported user is in `RESET_REQUIRED` and completes the
application's own password reset.

Pools never send email. `auto_verified_attributes` is empty and no email
configuration is set. The consuming application mints its own tokens,
sends mail through its own provider, and confirms outcomes with
`AdminSetUserPassword`, `AdminConfirmSignUp` and
`AdminUpdateUserAttributes`. This keeps SES, sandbox exits and sender
identity out of the platform.

Defaults follow dxw policy: 16-character minimum passwords, deletion
protection on, threat protection off. Clients relax them in their own
tfvars where a legacy policy must be honoured.

## Consequences

- The pool schema is immutable; `custom_attributes` is applied on create
  only; changing it later is silently ignored (`ignore_changes = [schema]`),
  so a new attribute needs a new pool under a new key.
- Threat protection moves the pool to the Plus plan with per-user cost, so
  it is an explicit opt-in.
- Imported users receive new `sub` values; applications keyed on `sub`
  must re-key during cutover.
- No hosted UI, OAuth, federation, MFA or SES. Any of these is a new
  decision.
- Registration relies on the public `SignUp` call (protected by the client
  secret hash) followed by `AdminConfirmSignUp`; `admin_create_user_config`
  is deliberately left open and `AdminCreateUser` is not in the default
  action set.
