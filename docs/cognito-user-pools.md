# Cognito user pools

How to declare a pool, wire a service to it, and migrate users from a pool
outside Dalmatian. Placeholders: `<infrastructure>`, `<environment>`,
`<pool>`, `<client>`, `<service>`, `<new pool id>`, `<source pool id>`.

## Declare a pool

In the infrastructure's tfvars (`dalmatian terraform-dependencies set-tfvars`):

```hcl
infrastructure_cognito_user_pools = {
  <pool> = {
    clients = { <client> = {} }
  }
}

infrastructure_ecs_cluster_services = {
  <service> = {
    cognito_user_pools = ["<pool>"]
  }
}
```

Deploy with `dalmatian deploy infrastructure -i <infrastructure> -e <environment>`.
Pool defaults are 16-character minimum passwords (`password_minimum_length`
is validated to 8-99; 16 is dxw policy), deletion protection on and threat
protection off. Client defaults come from `client_defaults` in
`infrastructure_cognito_user_pools_defaults` and apply to every client of
every pool unless the client overrides them: `USER_PASSWORD_AUTH` and
refresh auth flows, 60-minute access and ID tokens, and 1-day refresh
tokens. `custom_attributes` cannot be changed after the pool exists.

A service's task role is granted the Admin actions an application needs to
own registration, password reset, account state and session revocation by
default; overriding `cognito_user_pool_actions` requires a non-empty list
of specific `cognito-idp:` actions — wildcards are rejected.

## Wire a service

```
dalmatian cognito show-client -i <infrastructure> -e <environment> -p <pool> -c <client> -s
dalmatian service set-environment-variables -i <infrastructure> -e <environment> -s <service>
```

Paste the four `COGNITO_*` lines into the editor, add whatever mode flag
the application uses to select Cognito, save, confirm the diff, then
`dalmatian service deploy`.

Recreating an app client rotates its secret; rerun `show-client -s`, update
the env file and redeploy.

## Migrate users from a pool outside Dalmatian

Cognito cannot export passwords. Every imported user is created in
`RESET_REQUIRED` and must complete the application's reset flow. The
application must therefore handle `PasswordResetRequiredException` on
sign-in by routing to that flow, and must not depend on the Cognito `sub`,
which changes.

1. **Rehearse in staging.** Import the source's non-production pool into
   the staging pool and have the application team prove sign-in, reset and
   sign-out end to end before any production step.
2. **Fetch the new pool's CSV header.** In a shell with no source-account
   credentials exported:

   ```
   HEADER="$(dalmatian aws exec -i <infrastructure> -e <environment> cognito-idp get-csv-header --user-pool-id <new pool id> | jq -c '.CSVHeader')"
   ```
3. **Freeze the source.** Disable registration and change-email in the
   source application for the cutover window, then take the extract.
4. **Extract.** With credentials for the source account (outside Dalmatian):

   ```
   {
     echo "$HEADER" | jq -r 'join(",")'
     aws cognito-idp list-users --user-pool-id <source pool id> \
       | jq -r --argjson header "$HEADER" '
           .Users[]
           | select(.UserStatus != "UNCONFIRMED")
           | (.Attributes | map({ (.Name): .Value }) | add) as $a
           | [ $header[] | if . == "cognito:username" then $a["email"]
                           elif . == "cognito:mfa_enabled" then "FALSE"
                           elif . == "email_verified" then "TRUE"
                           else ($a[.] // "") end ] | @csv'
   } > users.csv
   aws cognito-idp list-users --user-pool-id <source pool id> \
     | jq -r '.Users[] | select(.Enabled == false) | .Attributes[] | select(.Name == "email") | .Value' \
     > disabled.txt
   ```

   Unconfirmed users are excluded. Both files are personal data: keep
   them on your machine only, never commit them, delete them after
   step 6.
5. **Import.** `dalmatian cognito import-users -i <infrastructure> -e <environment> -p <pool> -f users.csv`.
   Then disable each address in `disabled.txt` with
   `dalmatian aws exec ... cognito-idp admin-disable-user --user-pool-id <new pool id> --username <email>`.
6. **Reconcile.** Source `list-users` count minus excluded unconfirmed
   users must equal `dalmatian cognito list-pools` `estimated_users`
   (allow the estimate a few minutes to settle). Fix any failed rows from
   the import job's CloudWatch log group and rerun with `-F`.
7. **Wire and cut over.** Wire the service as above, deploy, move DNS.
   Keep the source pool read-only for the agreed rollback window.

## Remove a pool

Deletion protection blocks both `terraform destroy` and removing the pool's
block from tfvars. Set `deletion_protection = false` in tfvars, deploy, then
remove the block and deploy again.

Renaming a pool key destroys and recreates the pool (the key is the
`for_each` key) and is blocked by deletion protection for the same reason.

## Backup

`dalmatian cognito export-users -i <infrastructure> -e <environment> -p <pool> -o backup.csv`
writes a re-importable CSV. Passwords are not included; a restore puts
every user back into `RESET_REQUIRED`.
