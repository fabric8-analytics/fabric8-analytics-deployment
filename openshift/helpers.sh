
function is_set_or_fail() {
    local name=$1
    local value=$2

    if [ "${value}" == "not-set" ]; then
        echo "You have to set $name" >&2
        exit 1
    fi
}

function tool_is_installed() {
# Check if given command is available on this machine
    local cmd=$1

    if ! [ -x "$(command -v $cmd)" ]; then
        echo "Error: ${cmd} command is not available. Please install it. See README.md file for more information." >&2
        exit 1
    fi
}

function generate_and_deploy_config() {
    oc process -p DEPLOYMENT_PREFIX="${DEPLOYMENT_PREFIX}" \
    -p KEYCLOAK_URL="${KEYCLOAK_URL}" \
    -p AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION}" \
    -f "${here}/config-template.yaml" > "${here}/config.yaml"
    oc apply -f config.yaml
}

function deploy_secrets() {
    #All secrets must be base64 encoded
    oc process -p AWS_ACCESS_KEY_ID="$(/bin/echo -n "${AWS_ACCESS_KEY_ID}" | base64)" \
    -p AWS_SECRET_ACCESS_KEY="$(/bin/echo -n "${AWS_SECRET_ACCESS_KEY}" | base64)" \
    -p AWS_DEFAULT_REGION="$(/bin/echo -n "${AWS_DEFAULT_REGION}" | base64)" \
    -p GITHUB_API_TOKENS="$(/bin/echo -n "${GITHUB_API_TOKENS}" | base64)" \
    -p GITHUB_OAUTH_CONSUMER_KEY="$(/bin/echo -n "${GITHUB_OAUTH_CONSUMER_KEY}" | base64)" \
    -p GITHUB_OAUTH_CONSUMER_SECRET="$(/bin/echo -n "${GITHUB_OAUTH_CONSUMER_SECRET}" | base64)" \
    -p LIBRARIES_IO_TOKEN="$(/bin/echo -n "${LIBRARIES_IO_TOKEN}" | base64)" \
    -p FLASK_APP_SECRET_KEY="$(/bin/echo -n "${FLASK_APP_SECRET_KEY}" | base64)" \
    -p RDS_ENDPOINT="$(/bin/echo -n "${RDS_ENDPOINT}" | base64)" \
    -p RDS_PASSWORD="$(/bin/echo -n "${RDS_PASSWORD}" | base64)" \
    -p SNYK_TOKEN="$(/bin/echo -n "${SNYK_TOKEN}" | base64)" \
    -p SNYK_ISS="$(/bin/echo -n "${SNYK_ISS}" | base64)" \
    -p HPF_MAVEN_INSIGHTS_BUCKET="$(/bin/echo -n "${USER_ID}-hpf-insights" | base64)" \
    -f "${here}/secrets-template.yaml" > "${here}/secrets.yaml"
    oc apply -f secrets.yaml
}

function oc_process_apply() {
    echo -e "\\n Processing template - $1 ($2) \\n"
    # Don't quote $2 as we need it to split into individual arguments
    oc process -f "$1" $2 | oc apply -f -
}

function openshift_login() {
    oc login "${OC_URI}" --token="${OC_TOKEN}" --insecure-skip-tls-verify=true
}

function purge_aws_resources() {
    echo "Removing previously allocated AWS resources"
    # Purges $DEPLOYMENT_PREFIX prefixed SQS queues, S3 buckets and DynamoDB tables.
    python3 ./purge_AWS_resources.py
}

function remove_project_resources() {
    echo "Removing all openshift resources from selected project"
    oc delete all,cm,secrets --all
    if [ "$purge_aws_resources" == true ]; then
        purge_aws_resources
    fi
}

function delete_project_and_aws_resources() {
    if oc get project "${OC_PROJECT}"; then
        echo "Deleting project ${OC_PROJECT}"
        oc delete project "${OC_PROJECT}"
    fi
    purge_aws_resources
}

function create_or_reuse_project() {
    if oc get project "${OC_PROJECT}"; then
        oc project "${OC_PROJECT}"
        remove_project_resources
    else
        oc new-project "${OC_PROJECT}"
    fi
}

function tag_rds_instance() {
    TAGS="Key=ENV,Value=${DEPLOYMENT_PREFIX}"
    echo "Tagging RDS instance with ${TAGS}"
    aws rds add-tags-to-resource \
            --resource-name "${RDS_ARN}" \
            --tags "${TAGS}" >/dev/null
}

function get_rds_instance_info() {
    aws --output=json rds describe-db-instances --db-instance-identifier "${RDS_INSTANCE_NAME}" 2>/dev/null 1>rds.json
    return $?
}

function allocate_aws_rds() {
    if ! get_rds_instance_info; then
        aws rds create-db-instance \
        --allocated-storage "${RDS_STORAGE}" \
        --db-instance-identifier "${RDS_INSTANCE_NAME}" \
        --db-instance-class "${RDS_INSTANCE_CLASS}" \
        --db-name "${RDS_DBNAME}" \
        --engine postgres \
        --engine-version "9.6.1" \
        --master-username "${RDS_DBADMIN}" \
        --master-user-password "${RDS_PASSWORD}" \
        --publicly-accessible \
        --storage-type gp2
        #--storage-encrypted
        echo "Waiting (60s) for ${RDS_INSTANCE_NAME} to come online"
        sleep 60
        wait_for_rds_instance_info
    else
        echo "DB instance ${RDS_INSTANCE_NAME} already exists"
        wait_for_rds_instance_info
        if [ "$purge_aws_resources" == true ]; then
            echo "recreating database"
            PGPASSWORD="${RDS_PASSWORD}" psql -d template1 -h "${RDS_ENDPOINT}" -U "${RDS_DBADMIN}" -c "drop database ${RDS_DBNAME}"
            PGPASSWORD="${RDS_PASSWORD}" psql -d template1 -h "${RDS_ENDPOINT}" -U "${RDS_DBADMIN}" -c "create database ${RDS_DBNAME}"
        fi
    fi
    tag_rds_instance
}

function wait_for_rds_instance_info() {
    while true; do
        echo "Trying to get RDS DB endpoint for ${RDS_INSTANCE_NAME} ..."

        get_rds_instance_info
        RDS_ENDPOINT=$(jq -r '.DBInstances[0].Endpoint.Address' rds.json)
        RDS_ARN=$(jq -r '.DBInstances[0].DBInstanceArn' rds.json)

        if [ -z "${RDS_ENDPOINT}" ]; then
            echo "DB is still initializing, waiting 30 seconds and retrying ..."
            sleep 30
        else
            break
        fi
    done
}

