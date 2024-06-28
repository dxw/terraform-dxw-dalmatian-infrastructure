#!/bin/bash

# exit on failures
set -e
set -o pipefail

usage() {
  echo "Usage: $(basename "$0") [OPTIONS]" 1>&2
  echo "  -h   - help"
  echo "  -a   - CodeDeploy application name"
  echo "  -g   - CodeDeploy group name"
  echo "  -A   - Appspec content"
  echo "  -S   - Appspec sha256"
  exit 1
}

while getopts "a:g:A:S:h" opt; do
  case $opt in
    a)
      APPLICATION_NAME=$OPTARG
      ;;
    g)
      GROUP_NAME=$OPTARG
      ;;
    A)
      APPSPEC_CONTENT=$OPTARG
      ;;
    S)
      APPSPEC_SHA=$OPTARG
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
  -z "$APPLICATION_NAME" ||
  -z "$GROUP_NAME" ||
  -z "$APPSPEC_CONTENT" ||
  -z "$APPSPEC_SHA"
]]
then
  usage
fi

DEPLOYMENT_REVISION=$(
  jq -rn \
  --arg appspec_content "$APPSPEC_CONTENT" \
  --arg appspec_sha "$APPSPEC_SHA" \
  '{
    revisionType: "AppSpecContent",
    appSpecContent: {
      content: $appspec_content,
      sha256: $appspec_sha
    }
  }'
)

echo "==> Checking current Deployments for '$APPLICATION_NAME' ..."
CURRENT_DEPLOYMENT="deployment_check"
while [ -n "$CURRENT_DEPLOYMENT" ]
do
  CURRENT_DEPLOYMENT=$(aws deploy list-deployments \
    --application-name "$APPLICATION_NAME" \
    --deployment-group-name "$GROUP_NAME" \
    --include-only-statuses Created InProgress Queued \
    --output text \
    | head -n1
  )
  if [ -n "$CURRENT_DEPLOYMENT" ]
  then
    echo "There is a current deployment In Progress or Queued ($(echo "$CURRENT_DEPLOYMENT" | cut -d' ' -f2)). Waiting before creating a new one ..."
    sleep 10
  fi
done

echo "==> Creating Deployment for '$APPLICATION_NAME' ..."
DEPLOYMENT_ID=$(
  aws deploy create-deployment \
  --application-name "$APPLICATION_NAME" \
  --deployment-group-name "$GROUP_NAME" \
  --revision "$DEPLOYMENT_REVISION" \
  --output text \
  --query '[deploymentId]'
)

echo "==> Checking deployment '$DEPLOYMENT_ID' ..."
DEPLOYMENT_STATUS=$(
  aws deploy get-deployment \
  --deployment-id "$DEPLOYMENT_ID" \
  --output text \
  --query '[deploymentInfo.status]'
)

while [[
  $DEPLOYMENT_STATUS == "Created" ||
  $DEPLOYMENT_STATUS == "InProgress" ||
  $DEPLOYMENT_STATUS == "Pending" ||
  $DEPLOYMENT_STATUS == "Queued" ||
  $DEPLOYMENT_STATUS == "Ready"
]]
do
  echo "==> Deployment status: $DEPLOYMENT_STATUS..."
  DEPLOYMENT_STATUS=$(
    aws deploy get-deployment \
    --deployment-id "$DEPLOYMENT_ID" \
    --output text \
    --query '[deploymentInfo.status]'
  )
  sleep 10
done

if [[ $DEPLOYMENT_STATUS == "Succeeded" ]]
then
  echo "==> Deployment Succeeded!"
else
  echo "==> Deployment Failed! (Status: $DEPLOYMENT_STATUS)"
  exit 1
fi

# Original script sourced from https://dev.to/aws-builders/ecs-bluegreen-deployment-with-codedeploy-and-terraform-3gf1
# Thanks :)
