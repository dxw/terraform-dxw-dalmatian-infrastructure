#!/bin/bash

set -e
set -o pipefail

eval "$(jq -r '@sh "S3_PATH=\(.s3_path)"')"

URL="$(aws s3 presign "s3://$S3_PATH")"
jq -n \
  --arg url "$URL" \
  '{
    url: $url
  }'
