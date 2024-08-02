#!/bin/bash

# exit on failures
set -e
set -o pipefail

usage() {
  echo "Usage: $(basename "$0") [OPTIONS]" 1>&2
  echo "  -h   - help"
  echo "  -n   - CodeBuild project name"
  exit 1
}

while getopts "n:h" opt; do
  case $opt in
    n)
      PROJECT_NAME=$OPTARG
      ;;
    h)
      usage
      ;;
    *)
      usage
      ;;
  esac
done

if [ -z "$PROJECT_NAME" ]
then
  usage
fi

BUILD_ID="$(
  aws codebuild start-build \
  --project-name "$PROJECT_NAME" \
  | jq -r '.build.id'
)"

echo "Triggered $PROJECT_NAME CodeBuild project ($BUILD_ID) ..."

COMPLETED=""
while [ -z "$COMPLETED" ]
do
  sleep 10
  echo "Checking progress of CodeBuild  $BUILD_ID ..."
  BUILD_PROGRESS="$(
    aws codebuild batch-get-builds \
    --ids "$BUILD_ID" \
  )"
  COMPLETED="$(
    echo "$BUILD_PROGRESS" \
    | jq -r \
    '.builds[0].phases[] | select(.phaseType == "COMPLETED")'
  )"
done
echo "CodeBuild $BUILD_ID Completed, checking for failures ..."

FAILURES="$(
  echo "$BUILD_PROGRESS" \
  | jq -r \
  '.builds[0].phases[] | select(.phaseStatus == "FAILED")'
)"

if [ -n "$FAILURES" ]
then
  echo "$FAILURES"
  exit 1
fi

echo "CodeBuild $BUILD_ID completed without failures"
