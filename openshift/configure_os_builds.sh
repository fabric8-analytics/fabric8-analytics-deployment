#!/usr/bin/env bash
# This script creates directory buildroot with checkout of following projects

source helpers.sh
source env.sh

GITHUB_USERNAME="fabric8-analytics"

templates="fabric8-analytics-jobs fabric8-analytics-server fabric8-analytics-data-model
fabric8-analytics-worker fabric8-analytics-pgbouncer gremlin-docker
fabric8-analytics-scaler fabric8-analytics-firehose-fetcher
fabric8-analytics-license-analysis fabric8-analytics-stack-analysis
f8a-server-backbone fabric8-analytics-stack-report-ui fabric8-analytics-api-gateway"

openshift_login
oc create secret generic github --from-file=.gitconfig

for repo in $templates
do
  oc new-build "https://github.com/${GITHUB_USERNAME}/${repo}.git" --strategy=docker
  oc set build-secret --source "bc/${repo}" github
  oc start-build "$repo"
done
