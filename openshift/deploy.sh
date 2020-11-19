#!/bin/bash -e

# Deploy fabric8-analytics to Openshift
# possible arguments:
#   --purge-aws-resources: clear previously allocated AWS resources (RDS database, SQS queues, S3 buckets, DynamoDB tables)

here=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

source helpers.sh

#Check for configuration file
if ! [ -f "${here}/env.sh" ]
then
    echo '`env.sh` configuration file is missing. You can create one from the template:'
    echo 'cp env-template.sh env.sh'
    echo
    echo 'Modify the `env.sh` configuration file as necessary. See README.md file for more information.'
    exit 1
fi

#Check if required commands are available
tool_is_installed aws
tool_is_installed awk
tool_is_installed psql
tool_is_installed oc
tool_is_installed jq

#Load configuration from env variables
source env.sh

#Check if required env variables are set
is_set_or_fail RDS_PASSWORD "${RDS_PASSWORD}"
is_set_or_fail RDS_INSTANCE_NAME "${RDS_INSTANCE_NAME}"
#is_set_or_fail OC_USERNAME "${OC_USERNAME}"
#is_set_or_fail OC_PASSWD "${OC_PASSWD}"
is_set_or_fail AWS_ACCESS_KEY_ID "${AWS_ACCESS_KEY_ID}"
is_set_or_fail AWS_SECRET_ACCESS_KEY "${AWS_SECRET_ACCESS_KEY}"
is_set_or_fail AWS_DEFAULT_REGION "${AWS_DEFAULT_REGION}"
is_set_or_fail OC_TOKEN "${OC_TOKEN}"

purge_aws_resources=false # default
for key in "$@"; do
    case $key in
        --purge-aws-resources)
            purge_aws_resources=true
            shift # next argument
            ;;
        *)  # unknown option
            shift # next argument
            ;;
    esac
done
[ "$purge_aws_resources" == false ] && echo "Use --purge-aws-resources if you want to also clear previously allocated AWS resources (RDS database, SQS queues, S3 buckets, DynamoDB tables)."

create_or_reuse_project
allocate_aws_rds
generate_and_deploy_config
deploy_secrets

github_org_base="https://raw.githubusercontent.com/fabric8-analytics"
openshift_template_path="master/openshift/template.yaml"
openshift_template_path2="master/openshift/template-prod.yaml"

oc_process_apply "${github_org_base}/fabric8-analytics-pgbouncer/${openshift_template_path}"
oc_process_apply "${github_org_base}/gremlin-docker/${openshift_template_path}" "-p CHANNELIZER=http -p REST_VALUE=1 -p IMAGE_TAG=latest -p CPU_REQUEST=100m -p CPU_LIMIT=250m"
oc_process_apply "${github_org_base}/gremlin-docker/${openshift_template_path}" "-p CHANNELIZER=http -p REST_VALUE=1 -p IMAGE_TAG=latest -p QUERY_ADMINISTRATION_REGION=ingestion -p CPU_REQUEST=100m -p CPU_LIMIT=250m"
sleep 20
oc_process_apply "${github_org_base}/fabric8-analytics-data-model/${openshift_template_path}"
oc_process_apply "${github_org_base}/fabric8-analytics-worker/${openshift_template_path}" "-p WORKER_ADMINISTRATION_REGION=api -p WORKER_RUN_DB_MIGRATIONS=1 -p WORKER_EXCLUDE_QUEUES=GraphImporterTask -p CPU_REQUEST=100m -p CPU_LIMIT=250m"
sleep 10
oc_process_apply "${github_org_base}/f8a-server-backbone/${openshift_template_path}"
oc_process_apply "${github_org_base}/fabric8-analytics-server/${openshift_template_path}"
oc_process_apply "${github_org_base}/fabric8-analytics-license-analysis/${openshift_template_path}" "-p CPU_REQUEST=100m -p CPU_LIMIT=250m"
# oc_process_apply "${github_org_base}/f8a-pypi-insights/${openshift_template_path}" "-p CPU_REQUEST=100m -p CPU_LIMIT=250m"
# oc_process_apply "${github_org_base}/fabric8-analytics-npm-insights/${openshift_template_path}" "-p CPU_REQUEST=100m -p CPU_LIMIT=250m"
# oc_process_apply "${github_org_base}/f8a-hpf-insights/${openshift_template_path2}" "-p HPF_SCORING_REGION=maven -p RESTART_POLICY=Always -p CPU_REQUEST=100m -p CPU_LIMIT=250m"
