# Static error pages from CloudFront

How to serve a static page when a service's backend answers 502, 503 or
504, so visitors see something friendlier than the load balancer's plain
text while the service recovers. Placeholders: `<service>`, `<bucket>`.

## How it works

A CloudFront custom error response swaps the body of an origin error for a
page fetched from a path on the same distribution. The page has to come
from somewhere other than the failing backend, so it lives in a custom S3
bucket served through the service's distribution at its own path.

CloudFront fetches an error page straight from the origin without running
the bucket's viewer-request function, so the path prefix is not stripped.
Key the object with the full path (`__errors/503.html` for a page at
`/__errors/503.html`). A wrong key shows up as S3's XML "Access Denied" in
place of the page, because CloudFront may not list the bucket and S3
answers a missing key with 403.

```hcl
custom_s3_buckets = {
  <bucket> = {
    use_aes256_encryption                              = true
    cloudfront_infrastructure_ecs_cluster_service      = "<service>"
    cloudfront_infrastructure_ecs_cluster_service_path = "/__errors/*"
    objects = {
      "__errors/503.html" = {
        content       = <<-HTML
          <!doctype html>
          <html lang="en"><head><meta charset="utf-8"><title>Back soon</title></head>
          <body><h1>Back soon</h1><p>Please try again in a few minutes.</p></body></html>
        HTML
        cache_control = "no-store"
      }
    }
  }
}

infrastructure_ecs_cluster_services = {
  <service> = {
    cloudfront_custom_error_responses = [
      { error_code = 502, response_page_path = "/__errors/503.html", error_caching_min_ttl = 30 },
      { error_code = 503, response_page_path = "/__errors/503.html", error_caching_min_ttl = 30 },
      { error_code = 504, response_page_path = "/__errors/503.html", error_caching_min_ttl = 30 },
    ]
  }
}
```

## Choices to make

- **Which codes.** 502, 503 and 504 are what an unhealthy, overloaded or
  unresponsive backend produces. A 500 is usually an application bug and
  its own error handling is more useful than a holding page.
- **Which status to return.** `response_code` defaults to the origin's
  code, which keeps the CloudFront and load balancer error metrics honest.
  Set it to return something else, for example 503 for all three.
- **Error caching.** `error_caching_min_ttl` is how long CloudFront serves
  the page without asking the origin again. Thirty seconds lets CloudFront
  absorb a retry storm instead of forwarding it to a struggling backend.
  The default is CloudFront's ten seconds.
- **The page itself.** Keep it self-contained: inline styles, no scripts
  or images fetched from the service, because the service is what is
  down. A `<meta http-equiv="refresh">` gives a tab left open a way back
  without anyone pressing reload. `cache_control = "no-store"` stops
  browsers keeping the page once the service is back.

## Things to know

- The page replaces the body of every matching error the distribution
  returns, including responses to the application's own API calls. The
  status code is unchanged, so client-side error handling still works; it
  receives HTML instead of the load balancer's text.
- The bucket's cache behaviour holds objects at the edge for a day by
  default, so after changing the page either wait or invalidate
  `/__errors/*` on the distribution.
- The bucket path is a normal path on the distribution. Pick one the
  application will never use, and note that the WAF sees requests to it
  like any other.
