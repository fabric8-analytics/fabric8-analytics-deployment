# This is a deployment configuration template with default values used to configure dev deployment of fabric8-analytics.
# It is recommended to copy this file and then modify it:
# $ cp env-template.sh env.sh


# (Required) Dev cluster
# Your dev cluster username
export OC_USERNAME='not-set'
# Your dev cluster password
export OC_PASSWD='not-set'
# Export dev cluster token
export OC_TOKEN='not-set'


# (Required) AWS credentials
export AWS_ACCESS_KEY_ID='not-set'
export AWS_SECRET_ACCESS_KEY='not-set'
# PostgreSQL/RDS password to be used
# You can generate a good password with `pwgen`:
# $ pwgen -1cs 32
export RDS_PASSWORD='not-set'

# (Required) Your OpenShift.io API token. You can find it on your profile page when you log in to https://openshift.io.
export RECOMMENDER_API_TOKEN='not-set'

# (Required) GitHub
# Comma-separated list of tokens for talking to GitHub API. Having just single token here is enough.
#   You can generate a token here: https://github.com/settings/tokens
export GITHUB_API_TOKENS='not-set'

# (Required) Get your Libraries.io API token here: https://libraries.io/account
export LIBRARIES_IO_TOKEN='not-set'

# Following section describes how to setup authentication for the jobs service. Feel free to skip it, if you don't need the service.
#
# Create a new GitHub OAuth App here: https://github.com/settings/developers
# You will need to provide homepage and callback URL; for the dev cluster, use following values (replace OC_USERNAME):
# "Homepage URL" is "http://bayesian-jobs-${OC_USERNAME}-fabric8-analytics.dev.rdu2c.fabric8.io/"
# "Authorization callback URL" is "http://bayesian-jobs-${OC_USERNAME}-fabric8-analytics.dev.rdu2c.fabric8.io/api/v1/authorized"
# In return, you'll get GITHUB_OAUTH_CONSUMER_KEY and GITHUB_OAUTH_CONSUMER_SECRET from GitHub.
#   Client ID is GITHUB_OAUTH_CONSUMER_KEY
#   Client Secret is GITHUB_OAUTH_CONSUMER_SECRET
export GITHUB_OAUTH_CONSUMER_KEY='not-set'
export GITHUB_OAUTH_CONSUMER_SECRET='not-set'


# ----------------------------------------------------------------------------------
# Non-essential configuration options follow. You likely don't need to touch these.

# Deployment prefix
export DEPLOYMENT_PREFIX=${DEPLOYMENT_PREFIX:-${OC_USERNAME}}

# Keycloak
export KEYCLOAK_URL='https://sso.openshift.io'

# Flask
export FLASK_APP_SECRET_KEY='notsosecret'

# Dev cluster
export OC_URI='devtools-dev.ext.devshift.net:8443'
export OC_PROJECT="${OC_USERNAME}-fabric8-analytics"

# AWS
export AWS_DEFAULT_REGION='us-east-1'
## RDS configuration variables are use to provision RDS instance
export RDS_ENDPOINT=''
export RDS_INSTANCE_NAME="${OC_USERNAME}-bayesiandb"
export RDS_INSTANCE_CLASS='db.t2.micro'
export RDS_DBNAME='postgres'
export RDS_DBADMIN='coreapi'
export RDS_STORAGE=5
export RDS_SUBNET_GROUP_NAME='dv peering az'
export RDS_ARN='not-set'

# URLs against which to run E2E tests
export F8A_API_URL='not-set'
export F8A_JOB_API_URL='not-set'

# Sentry URL
export SENTRY_DSN=''
