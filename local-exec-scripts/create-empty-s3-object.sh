#!/bin/bash

# exit on failures
set -e
set -o pipefail

usage() {
  echo "Usage: $(basename "$0") [OPTIONS]" 1>&2
  echo "  -h   - help"
  echo "  -b   - Bucket"
  echo "  -k   - Key"
  exit 1
}

while getopts "b:k:h" opt; do
  case $opt in
    b)
      BUCKET=$OPTARG
      ;;
    k)
      KEY=$OPTARG
      ;;
    h)
      usage
      ;;
    *)
      usage
      ;;
  esac
done

if [[
  -z "$BUCKET" ||
  -z "$KEY"
]]
then
  usage
fi

if ! aws s3api head-object --bucket "$BUCKET" --key "$KEY" 2>/dev/null
then
    # If the file does not exist, create an empty file
    touch /tmp/empty_file.txt
    aws s3api put-object --bucket "$BUCKET" --key "$KEY" --body /tmp/empty_file.txt
    rm /tmp/empty_file.txt
    echo "==> Empty file created in S3 bucket"
else
    echo "==> File already exists in S3 bucket, skipping creation"
fi
