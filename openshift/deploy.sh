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

#Load configuration from env variables
source env.sh

#Check if required env variables are set
is_set_or_fail RDS_PASSWORD "${RDS_PASSWORD}"
is_set_or_fail RDS_INSTANCE_NAME "${RDS_INSTANCE_NAME}"
is_set_or_fail OC_USERNAME "${OC_USERNAME}"
#is_set_or_fail OC_PASSWD "${OC_PASSWD}"
is_set_or_fail AWS_ACCESS_KEY_ID "${AWS_ACCESS_KEY_ID}"
is_set_or_fail AWS_SECRET_ACCESS_KEY "${AWS_SECRET_ACCESS_KEY}"
is_set_or_fail AWS_DEFAULT_REGION "${AWS_DEFAULT_REGION}"
is_set_or_fail OC_TOKEN "${OC_TOKEN}"

templates_dir="${here}/templates"
templates="fabric8-analytics-jobs fabric8-analytics-server fabric8-analytics-data-model
fabric8-analytics-worker fabric8-analytics-pgbouncer gremlin-docker
fabric8-analytics-license-analysis fabric8-analytics-stack-analysis
f8a-server-backbone fabric8-analytics-stack-report-ui fabric8-analytics-api-gateway"

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

openshift_login
create_or_reuse_project
allocate_aws_rds
generate_and_deploy_config
deploy_secrets

#Get templates for fabric8-analytics projects
for template in ${templates}
do
    curl -sS "https://raw.githubusercontent.com/fabric8-analytics/${template}/master/openshift/template.yaml" > "${templates_dir}/${template#fabric8-analytics-}.yaml"
done

oc_process_apply "${templates_dir}/pgbouncer.yaml"
sleep 20
oc_process_apply "${templates_dir}/gremlin-docker.yaml" "-p CHANNELIZER=http -p REST_VALUE=1 -p IMAGE_TAG=latest"
sleep 20
oc_process_apply "${templates_dir}/gremlin-docker.yaml" "-p CHANNELIZER=http -p REST_VALUE=1 -p IMAGE_TAG=latest -p QUERY_ADMINISTRATION_REGION=ingestion"
sleep 20
oc_process_apply "${templates_dir}/data-model.yaml"
sleep 20
oc_process_apply "${templates_dir}/jobs.yaml"
sleep 20
oc_process_apply "${templates_dir}/worker.yaml" "-p WORKER_ADMINISTRATION_REGION=ingestion -p WORKER_EXCLUDE_QUEUES=GraphImporterTask"
sleep 20
oc_process_apply "${templates_dir}/worker.yaml" "-p WORKER_ADMINISTRATION_REGION=ingestion -p WORKER_INCLUDE_QUEUES=GraphImporterTask -p WORKER_NAME_SUFFIX=-graph-import"
sleep 20
oc_process_apply "${templates_dir}/worker.yaml" "-p WORKER_ADMINISTRATION_REGION=api -p WORKER_RUN_DB_MIGRATIONS=1 -p WORKER_EXCLUDE_QUEUES=GraphImporterTask"
sleep 20
oc_process_apply "${templates_dir}/worker.yaml" "-p WORKER_ADMINISTRATION_REGION=api -p WORKER_INCLUDE_QUEUES=GraphImporterTask -p WORKER_NAME_SUFFIX=-graph-import"
sleep 20
oc_process_apply "${templates_dir}/f8a-server-backbone.yaml"
sleep 20
oc_process_apply "${templates_dir}/server.yaml"
sleep 20
oc_process_apply "${templates_dir}/stack-analysis.yaml" "-p KRONOS_SCORING_REGION=maven"
# kronos-pypi is not used/maintained now
# sleep 20
# oc_process_apply "${templates_dir}/stack-analysis.yaml" "-p KRONOS_SCORING_REGION=pypi"
sleep 20
oc_process_apply "${templates_dir}/license-analysis.yaml"
sleep 20
oc_process_apply "${templates_dir}/stack-report-ui.yaml" "-p REPLICAS=1"
sleep 20
oc_process_apply "${templates_dir}/api-gateway.yaml"
