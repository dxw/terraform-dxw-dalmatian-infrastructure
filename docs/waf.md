# WAF ACLs for CloudFront

How `infrastructure_ecs_cluster_wafs` builds a WAF ACL, the order its rules
run in, and how to use geo challenges, Bot Control, scoped rate rules and
logging. Placeholders: `<infrastructure>`, `<environment>`, `<service>`,
`<bucket>`, `<workspace>`.

## What it creates

Each key in `infrastructure_ecs_cluster_wafs` becomes one CloudFront-scope
`aws_wafv2_web_acl` in us-east-1. A service distribution attaches it with
`cloudfront_waf_association = "<key>"` in `infrastructure_ecs_cluster_services`;
a custom S3 bucket's dedicated distribution attaches it with the same field
in `custom_s3_buckets`. An ACL can be shared, but see "One ACL per audience".

## Rule order

WAF evaluates rules by ascending priority and stops at the first terminating
action (Allow or Block). Challenge and CAPTCHA terminate only when the
request has no valid token; with a token the request carries on to the next
rule.

| Priority | Rule | Source field |
|---|---|---|
| 0 | Block IPv4 deny list | `ipv4_deny_list` |
| 1 | Allow IPv4 allow list | `ipv4_allow_list` |
| 2 | Block IPv6 deny list | `ipv6_deny_list` |
| 3 | Allow IPv6 allow list | `ipv6_allow_list` |
| 4 | Bot Control, only when `geo_rule_verified_bot_categories` is set | `aws_managed_rules` |
| 5 | `VerifiedBotGeoExemption`, only when `geo_rule_verified_bot_categories` is set | `geo_rule_verified_bot_categories` |
| 10 + n | Geo rules, in list order | `geo_rules` |
| 100 + n | AWS managed rule groups, in list order | `aws_managed_rules` |
| 200 + n | Scoped rate rules, in list order | `rate_rules` |
| 1000 | Site-wide per-IP rate limit | `rate_limiting` |

The allow lists terminate with Allow, so an allow-listed address skips every
rule after priority 3: no geo challenge, no Bot Control, no rate limits. Use
them for staff abroad, load-test generators and uptime checkers, and remove
entries when they are no longer needed.

Cheap rules run first on purpose. Bot Control is billed per request it
inspects, so put it last in `aws_managed_rules` and let the geo rules and the
other groups dispose of traffic before it. The exception is
`geo_rule_verified_bot_categories`, which moves it before the geo rules
because they need its labels.

## Challenge versus CAPTCHA

**Challenge** returns a silent JavaScript interstitial. A browser solves it
without user interaction, receives a token cookie for the site's domain, and
sends that cookie on every later request, including `fetch` and XHR calls
from the same origin. It suits whole-site rules such as a geo match.

**CAPTCHA** shows a puzzle the visitor must solve. It can only be rendered for
a page navigation. A CAPTCHA served in response to a `fetch` or XHR call
cannot be displayed, so the application sees a failed request. Use CAPTCHA
only on paths that are page navigations, or on API paths once the
application has integrated the AWS WAF JavaScript SDK, which renders the
puzzle inside the page and refreshes tokens without a navigation.

For single-page applications set `challenge_immunity_time_sec` to at least a
day. The WAF default is 300 seconds, after which the next API call from an
otherwise idle tab is challenged again and, without the SDK, fails.

## One ACL per audience

Give an assets or uploads distribution its own ACL with no geo, Bot Control
or CAPTCHA rules. Images, stylesheets and scripts are loaded cross-origin by
the browser and cannot answer a challenge, so a shared ACL with a geo
challenge shows non-UK visitors a page with no images. A shared ACL also
sends every asset request through Bot Control, which you pay for.

## Bot Control

Naming `AWSManagedRulesBotControlRuleSet` is enough for the COMMON inspection
level. Set `bot_control_inspection_level = "TARGETED"` for the behavioural
rules, which also want the client SDK in the application.

Start the group with `action = "count"`, read its per-rule CloudWatch metrics
for a few days, then switch to `block`. Two rules commonly catch legitimate
traffic: `CategoryMonitoring` (uptime checkers) and
`SignalNonBrowserUserAgent` (scripts and load generators). Either allow-list
those sources or keep the two rules counting with `exclude_rules`.

## Letting verified bots past a geo rule

A geo rule that challenges visitors from abroad also challenges the robots
that social networks and search engines send to read a page. They cannot run
the challenge, so they get the empty interstitial: shared links show no
preview card, and search engines cannot index the site.

```hcl
geo_rule_verified_bot_categories = ["social_media", "page_preview", "search_engine"]
```

With this set, Bot Control runs at priority 4, before the geo rules. A
count-only rule at priority 5, `VerifiedBotGeoExemption`, adds the label
`dalmatian:verified-bot-geo-exempt` to requests that Bot Control labelled
`bot:verified` and placed in one of the listed categories. Every geo rule in
the ACL skips requests with that label. Everything after the geo rules still
applies to them: the managed groups and the rate limits.

Bot Control verifies a bot by its source address, not its User-Agent, so
claiming to be `Twitterbot` is not enough to skip the challenge. Do not
replace this with a User-Agent match for that reason.

Categories Bot Control uses: `advertising`, `ai`, `archiver`,
`content_fetcher`, `email_client`, `http_library`, `link_checker`,
`miscellaneous`, `monitoring`, `page_preview`, `scraping_framework`,
`search_engine`, `security`, `seo`, `social_media`, `webhooks`. AWS documents
`page_preview` as a rule (`CategoryPagePreview`) but it was not yet in the
rule group's `AvailableLabels` in October 2026; listing it is harmless and
takes effect when AWS starts using it. A name that is not in Bot Control's
list passes validation and never matches, so check the labels in the logs
after deploying. AWS lists the current set as `AvailableLabels` from `aws
wafv2 describe-managed-rule-group --scope CLOUDFRONT --vendor-name AWS --name
AWSManagedRulesBotControlRuleSet`.

Costs and caveats:

- Bot Control is billed per request inspected. Running it first means it
  also inspects the requests the geo rule would have challenged first.
- Paths in Bot Control's `excluded_path_patterns` get no Bot Control
  labels, so verified bots are still challenged on those paths.
- Never set it on an ACL without a geo rule; it would only add cost.

To check it works, after the deploy:

```
fields @timestamp, httpRequest.country, action, terminatingRuleId
| filter @message like /verified-bot-geo-exempt/
| stats count() by action, httpRequest.country
```

## Managed rule groups

`exclude_rules` overrides named rules in a group to count, `challenge_rules`
to challenge and `captcha_rules` to CAPTCHA. Rule names are the ones AWS
publishes for each group, for example `SizeRestrictions_BODY` in the Common
rule set or `HostingProviderIPList` in the Anonymous IP list.

Sites with user-generated content usually need `CrossSiteScripting_BODY`,
`GenericRFI_BODY` and `SizeRestrictions_BODY` (Common) and `SQLi_BODY` (SQLi)
counting rather than blocking, because free text in a POST body looks like
an attack to those rules.

## Scoped rate rules

`rate_rules` count requests per client IP whose URI path matches
`path_regex`, optionally restricted to the listed `methods`. `limit` is per
`evaluation_window_sec` (60, 120, 300 or 600). The `block` action answers
with the same 429 response as the site-wide limit. Typical use is a low
limit on POSTs to login, registration and password-reset paths to stop
credential stuffing.

## Logging

`logging = { enabled = true }` creates a CloudWatch log group
`aws-waf-logs-<infrastructure>-<environment>-<key>` in us-east-1 (the
`aws-waf-logs-` prefix is required by WAF), a resource policy that lets the
WAF log delivery service write to it, and a logging configuration on the
ACL. The group uses AWS-managed encryption because the infrastructure KMS
key is in eu-west-2 and CloudWatch Logs cannot use a key from another
region. `retention` defaults to 30 days. The `Cookie` and `Authorization`
headers are redacted; query strings and paths are not, so one-time OAuth
codes and reset tokens do appear until they expire.

CloudWatch Logs allows ten resource policies per account per region and the
limit cannot be raised. Each infrastructure and environment that enables
logging uses one in us-east-1, shared with anything else in the account that
needs one (Route 53 query logging, for example). Check the count before
enabling it in a busy account.

Blocked and challenged requests by rule, in CloudWatch Logs Insights:

```
fields @timestamp, httpRequest.clientIp, httpRequest.country, terminatingRuleId, action
| filter action != "ALLOW"
| stats count() by terminatingRuleId, action
```

## Worked example

Two ACLs: `app` on the service distribution, `uploads` on the bucket's
distribution.

```hcl
infrastructure_ecs_cluster_wafs = {
  app = {
    aws_managed_rules = [
      { name = "AWSManagedRulesAmazonIpReputationList", action = "block" },
      { name = "AWSManagedRulesKnownBadInputsRuleSet", action = "block" },
      {
        name          = "AWSManagedRulesCommonRuleSet"
        action        = "block"
        exclude_rules = ["CrossSiteScripting_BODY", "GenericRFI_BODY", "SizeRestrictions_BODY"]
      },
      { name = "AWSManagedRulesSQLiRuleSet", action = "block", exclude_rules = ["SQLi_BODY"] },
      {
        name            = "AWSManagedRulesAnonymousIpList"
        action          = "block"
        challenge_rules = ["AnonymousIPList", "HostingProviderIPList"]
      },
      { name = "AWSManagedRulesBotControlRuleSet", action = "count", bot_control_inspection_level = "COMMON" },
    ]
    geo_rules = [
      {
        name                = "ChallengeOutsideUK"
        country_codes       = ["GB", "JE", "GG", "IM"]
        negate              = true
        action              = "challenge"
        excluded_path_regex = "^/auth/callback/"
      }
    ]
    geo_rule_verified_bot_categories = ["social_media", "page_preview", "search_engine"]
    rate_rules = [
      {
        name       = "AuthRateLimit"
        limit      = 20
        action     = "block"
        path_regex = "^/(login|register|forgot_password)$"
        methods    = ["POST"]
      }
    ]
    rate_limiting = { enabled = true, limit = 2000 }
    challenge_immunity_time_sec = 86400
    logging = { enabled = true }
  }
  uploads = {
    aws_managed_rules = [
      { name = "AWSManagedRulesAmazonIpReputationList", action = "block" },
    ]
    rate_limiting = { enabled = true }
  }
}

infrastructure_ecs_cluster_services = {
  <service> = {
    cloudfront_waf_association = "app"
  }
}

custom_s3_buckets = {
  <bucket> = {
    cloudfront_dedicated_distribution = true
    cloudfront_waf_association        = "uploads"
  }
}
```

Plan with `dalmatian deploy infrastructure -w <workspace> -p` and read the
geo rule's statement: with `negate` and `excluded_path_regex` it must be an
`and_statement` of `not_statement { geo_match_statement }` and
`not_statement { regex_match_statement }`.
With `geo_rule_verified_bot_categories` set, the and_statement gains a third
statement, `not_statement { label_match_statement { key =
"dalmatian:verified-bot-geo-exempt" } }`, and the plan shows Bot Control at
priority 4 and `VerifiedBotGeoExemption` at 5.
