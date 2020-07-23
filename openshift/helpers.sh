
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
    oc process -p AWS_ACCESS_KEY_ID="$(echo -n "${AWS_ACCESS_KEY_ID}" | base64)" \
    -p AWS_SECRET_ACCESS_KEY="$(echo -n "${AWS_SECRET_ACCESS_KEY}" | base64)" \
    -p AWS_DEFAULT_REGION="$(echo -n "${AWS_DEFAULT_REGION}" | base64)" \
    -p GITHUB_API_TOKENS="$(echo -n "${GITHUB_API_TOKENS}" | base64)" \
    -p GITHUB_OAUTH_CONSUMER_KEY="$(echo -n "${GITHUB_OAUTH_CONSUMER_KEY}" | base64)" \
    -p GITHUB_OAUTH_CONSUMER_SECRET="$(/bin/echo -n "${GITHUB_OAUTH_CONSUMER_SECRET}" | base64)" \
    -p LIBRARIES_IO_TOKEN="$(echo -n "${LIBRARIES_IO_TOKEN}" | base64)" \
    -p FLASK_APP_SECRET_KEY="$(echo -n "${FLASK_APP_SECRET_KEY}" | base64)" \
    -p RDS_ENDPOINT="$(echo -n "${RDS_ENDPOINT}" | base64)" \
    -p RDS_PASSWORD="$(echo -n "${RDS_PASSWORD}" | base64)" \
    -p SNYK_TOKEN="$(echo -n "${SNYK_TOKEN}" | base64)" \
    -p SNYK_ISS="$(echo -n "${SNYK_ISS}" | base64)" \
    -p CVAE_NPM_INSIGHTS_BUCKET="$(echo -n "${USER_ID}-cvae-npm-insights" | base64)" \
    -p HPF_PYPI_INSIGHTS_BUCKET="$(echo -n "${USER_ID}-hpf-pypi-insights" | base64)" \
    -p HPF_MAVEN_INSIGHTS_BUCKET="$(echo -n "${USER_ID}-hpf-maven-insights" | base64)" \
    -f "${here}/secrets-template.yaml" > "${here}/secrets.yaml"
    oc apply -f secrets.yaml
}

function oc_process_apply() {
    echo -e "\\n Processing template - $1 ($2) \\n"
    # Don't quote $2 as we need it to split into individual arguments
    oc process -f "$1" $2 | oc apply -f - --wait=true
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

function allocate_aws_rds() {
    RDS_ENDPOINT="f8a-postgres"
    oc apply -f postgres.yaml --wait=true
}

