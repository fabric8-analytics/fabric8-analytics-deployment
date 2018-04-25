source helpers.sh
source env.sh

templates="fabric8-analytics-jobs fabric8-analytics-server fabric8-analytics-data-model
fabric8-analytics-worker fabric8-analytics-pgbouncer gremlin-docker
fabric8-analytics-scaler fabric8-analytics-firehose-fetcher
fabric8-analytics-license-analysis fabric8-analytics-stack-analysis
f8a-server-backbone fabric8-analytics-stack-report-ui fabric8-analytics-api-gateway"

remotes="humaton"
mkdir -p buildroot
cd buildroot

for repo in $templates
do
  fullrepo=${repo}
  if ! `ls $fullrepo &>/dev/null`; then
    git clone "git@github.com:fabric8-analytics/${fullrepo}.git"
  fi

  if [[ -n "$remotes" ]]; then
    pushd $fullrepo &>/dev/null
    if ! `git remote show | grep "^fork$" &>/dev/null`; then
      git remote add fork "git@github.com:${remotes}/${fullrepo}.git"
      git fetch --all
    fi
    popd &>/dev/null
  fi
done

openshift_login

for template in ${templates}
do
    cd ${repo}
    oc new-build https://github.com/fabric8-analytics/${template} --strategy=docker
    oc start-build ${template}  --from-dir=./
    cd ..
done