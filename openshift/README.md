# OpenShift green field deployment of fabric8-analytics services

## Install required tools

Use your preferred package manager to install aws-cli, psql, origin-clients, pwgen

on Fedora:
`sudo dnf install awscli pwgen postgresql origin-clients`

Mac users will require to install gawk from brew.

## Configure fabric8-analytics services

All configuration for the deployment script resides in env.sh.
To configure your development deployment copy [env-template.sh](env-template.sh) to env.sh

`cp env-template.sh env.sh`

Update variables with your AWS, Openshift and Github credentials.

### Generate RDS pasword

To generate password you will require tool named `pwgen`.
`pwgen -1cs 32`

Use generated password to update RDS_PASSWORD value.

## Configure Sentry DSN
fabric8-analytics supports Sentry monitoring. In case you have DSN for your Sentry instance, simply replace `SENTRY_DSN` variable. 

### Run oc login

dev cluster uses a self-signed certificate.
We need to log in using the command line and accept the certificate.

`oc login $OC_URI -u $OC_USERNAME -p $OC_PASSWD`

## Deploy fabric8-analytics services

Just run the deploy script and enjoy!

`$./deploy.sh`

If you have already run the script previously and therefore there exists a `$OC_PROJECT` project, the script purges it to start from scratch.
If you want to also purge previously allocated AWS resources (RDS db, SQS queues, S3 buckets, DynamoDB tables) use

`$./deploy.sh --purge-aws-resources`

Once you know that you no longer need the fabric8-analytics deployment, you can run

`$./cleanup.sh`

to remove the Openshift project and all allocated AWS resources.

### Dockerized deployment scripts

There's also [Dockerfile](Dockerfile) and [Makefile](Makefile) to run these scripts in docker container to avoid installing the required tools.
Just prepare your `env.sh` and run

- `make deploy` to (re-)deploy to Openshift
- `make clean-deploy` to purge fabric8-analytics project from Openshift along with allocated AWS resources and (re-)deploy
- `make clean` to remove fabric8-analytics project from Openshift along with allocated AWS resources

## Test not yet merged changes

Assume you have opened a PR in one of the [fabric8-analytics](https://github.com/fabric8-analytics) repositories.
Once tests pass in the PR, [CentosCI](https://ci.centos.org) builds your image and adds a similar comment to the PR:

`Your image is available in the registry: docker pull registry.devshift.net/fabric8-analytics/worker-scaler:SNAPSHOT-PR-25`

To update your dev deployment to use the above mentioned image you can use one the following ways:

- [oc edit](https://docs.openshift.com/container-platform/3.4/cli_reference/basic_cli_operations.html#edit) from command line
- editor in web interface: `Applications` -> `Deployments` -> select deployment -> `Actions` -> `Edit YAML`
- edit [deploy.sh](deploy.sh), add `"-p IMAGE_TAG=SNAPSHOT-PR-25"` (with correct tag) to corresponding `oc_process_apply` call at the end of the file and (re-)run `./deploy.sh`.

## E2E test

### Configure OSIO token

If you want to run E2E tests, you will need to configure `RECOMMENDER_API_TOKEN` variable in your `env.sh` file.
You can get the token on your [openshift.io](http://openshift.io) profile page after clicking on the "Update Profile" button.

### Run E2E tests against your deployment

First clone [E2E tests](https://github.com/fabric8-analytics/fabric8-analytics-common/tree/master/integration-tests)
(`git clone git@github.com:fabric8-analytics/fabric8-analytics-common.git`) repository, if you haven't done so already.

Then prepare your environment (you'll need your API token for this, see the previous section):

```shell
source env.sh
```

And finally run the tests in the same terminal window:
```shell
cd fabric8-analytics-common/integration-tests/
./runtest.sh
```
