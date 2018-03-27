source helpers.sh
source env.sh

templates="fabric8-analytics-jobs fabric8-analytics-server fabric8-analytics-data-model
fabric8-analytics-worker fabric8-analytics-pgbouncer gremlin-docker
fabric8-analytics-scaler fabric8-analytics-firehose-fetcher
fabric8-analytics-license-analysis fabric8-analytics-stack-analysis
f8a-server-backbone fabric8-analytics-stack-report-ui fabric8-analytics-api-gateway"

openshift_login

for template in ${templates}
do
    oc new-build --strategy=docker "https://github.com/fabric8-analytics/${template}/"
done