# CloudFront caching for services

How a service distribution decides what to cache, and how to add cache
behaviours for static assets. Placeholders: `<service>`.

## The default behaviour

`cloudfront_managed_cache_policy` on the service picks one of AWS's managed
cache policies for every path the extra behaviours below do not match.

- `CachingDisabled` sends every request to the origin. The application's
  `Cache-Control` headers are ignored at the edge.
- `UseOriginCacheControlHeaders-QueryStrings` caches exactly what the origin
  marks cacheable. Its TTLs are min 0, default 0 and max one year, so a
  response with no `Cache-Control` or `Expires` header is never cached,
  which keeps API responses safe. All cookies and all query strings are in
  the cache key, so a logged-in user never receives another user's cached
  response. Use this when the application sets its own cache headers.
- `CachingOptimized` caches everything for a day by default with nothing
  but the path in the key. Only suitable for a distribution that serves
  static files and nothing personalised.

## Extra behaviours for static assets

`cloudfront_cache_policies` declares custom cache policies for the service
and `cloudfront_cache_behaviours` attaches them to path patterns. The
policies default to min 0, default 86400, max one year, no cookies in the
key and all query strings kept, so an asset without cache headers is held
for a day, an asset with headers keeps its own TTL, and a cache-busting
query string still fetches a fresh copy. Leaving cookies out of the key
means logged-in and anonymous visitors share one cached copy of each asset.

```hcl
infrastructure_ecs_cluster_services = {
  <service> = {
    cloudfront_managed_cache_policy = "UseOriginCacheControlHeaders-QueryStrings"

    cloudfront_cache_policies = {
      static-assets = {}
    }
    cloudfront_cache_behaviours = [
      { path_pattern = "*.png", cache_policy = "static-assets" },
      { path_pattern = "*.jpg", cache_policy = "static-assets" },
      { path_pattern = "*.svg", cache_policy = "static-assets" },
      { path_pattern = "*.woff2", cache_policy = "static-assets" },
    ]
  }
}
```

Behaviours are evaluated in list order, after any behaviours created for
custom S3 buckets served through the same distribution. They use the same
origin, origin request policy and response headers policy as the default
behaviour, allow GET, HEAD and OPTIONS, and compress responses.

Two quotas apply per account: 20 custom cache policies and 25 cache
behaviours per distribution. One policy shared by several behaviours stays
well inside both.

`Host` is always part of the cache key and so always forwarded to the
origin, because the service load balancer routes on it and answers 421
without it. Any `headers_in_cache_key` you add are forwarded as well.

A `min_ttl` of 0 means `Cache-Control: no-store` from the origin is
honoured. Raising it forces caching for at least that long whatever the
origin says.
