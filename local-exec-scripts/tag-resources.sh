#!/bin/bash

# exit on failures
set -e
set -o pipefail

usage() {
  echo "Usage: $(basename "$0") [OPTIONS]" 1>&2
  echo "  -a   - Resource ARNs"
  echo "  -t   - Tags ('{\"Key\": \"Value\"}')"
  echo "  -d   - Delay in seconds before running"
  exit 1
}

while getopts "a:t:d:" opt; do
  case $opt in
    a)
      RESOURCE_ARNS=$OPTARG
      ;;
    t)
      TAGS=$OPTARG
      ;;
    d)
      DELAY=$OPTARG
      ;;
    *)
      usage
      ;;
  esac
done

sleep "$DELAY"

aws resourcegroupstaggingapi tag-resources --resource-arn-list "$RESOURCE_ARNS" --tags "$TAGS"
