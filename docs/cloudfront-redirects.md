# CloudFront redirects

`cloudfront_redirects` creates CloudFront distributions that answer every
request with a redirect to one fixed HTTPS target. Use it for alternative
domains (other TLDs, old names) that should send visitors to the canonical
site, without adding them to a service's `domain_names`, which would serve
the application on them instead.

Each entry gets its own distribution and CloudFront Function, separate from
any service's distribution. The function returns the redirect on
viewer-request, so the origin is never contacted and nothing is cached.

```hcl
cloudfront_redirects = {
  alt-domains = {
    aliases                = ["example.com", "www.example.com", "example.co.uk", "www.example.co.uk"]
    target                 = "https://example.org"
    status_code            = 301    # 301, 302, 307 or 308
    preserve_path          = true   # /a/b?x=1 -> https://example.org/a/b?x=1
    tls_certificate_arn    = null   # null: issue and validate one in the custom zones
    create_route53_records = true   # A and AAAA ALIAS records in the custom zones
    access_logging_enabled = false
  }
}
```

## Behaviour

- `http://` and `https://` requests both go straight to the target in one
  hop.
- With `preserve_path`, the path and query string are appended to
  `target` unchanged. A trailing slash on `target` is dropped first, so a
  target with a path prefix (`https://example.org/new/`) works. A parameter
  with an empty value comes out as the bare name (`?flag`).
- Only `GET` and `HEAD` are redirected; CloudFront answers other methods
  with `403`.
- No WAF is attached.

## Certificates and DNS

An alias belongs to the `custom_route53_hosted_zones` zone with the longest
name that equals it or is a suffix of it on a label boundary:
`www.example.com` falls in `example.com`.

| `tls_certificate_arn` | `create_route53_records` | Zones needed in this workspace |
|---|---|---|
| null | true | every alias |
| null | false | every alias (for validation); you point DNS yourself |
| set | true | every alias (for the records) |
| set | false | none: DNS is entirely yours |

A supplied certificate must be in us-east-1 and cover every alias. If you
point DNS yourself, an apex name needs an ALIAS/ANAME-capable provider.

Plans fail with the offending aliases named if a required zone is missing,
and if the same alias appears in two redirects.

## Deploying

An issued certificate waits up to 75 minutes for DNS validation and then
fails the deploy if the domain is not yet delegated to its zone. So:

1. Add each domain to `custom_route53_hosted_zones` and deploy.
2. Give the domain owner the zone's name servers. Wait until
   `dig +short NS example.com` returns them.
3. Add the `cloudfront_redirects` entry and deploy.
4. Check: `curl -sI 'http://example.com/a/b?x=1'` and the same over
   `https://` should both return the status code and
   `location: https://example.org/a/b?x=1`.

Do not declare the certificate's validation CNAME in `cname_records`. If
one is already there, the module's record takes it over without error, but
leave the hand-written entry in place: removing it deletes the record from
Route53 until the next deploy recreates it. Do not list a redirect alias in
`alias_records` when `create_route53_records` is on: that apply fails.

## Changing a redirect

Renaming a redirect's key destroys and recreates its distribution,
certificate and records. Change `aliases`, `target` or `status_code` in
place instead. Adding or removing an alias with an issued certificate
replaces the certificate (create before destroy) and revalidates it.
