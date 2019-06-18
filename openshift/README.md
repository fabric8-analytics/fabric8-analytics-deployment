# How to deploy fabric8-analytics services on OpenShift

## Install required tools

Use your preferred package manager to install `aws-cli`, `psql`, `origin-clients` and `pwgen`.

If you are running Fedora, then following command will do the trick:

```shell
$ sudo dnf install awscli pwgen postgresql origin-clients
```

Mac users will also need to install gawk from brew.

If you are running Mac, then following commands will do the trick:

```shell
$ brew install awscli
$ brew install postgres
$ brew install openshift-cli
$ brew install pwgen
```


## Open Merge Request for AWS Credentials
Next step is to get credentials to signin in your dev AWS Console
1. Make sure your Github/Gitlab account has primary email as `xyz@redhat.com`
2. Open a MR at https://gitlab.cee.redhat.com/dtsd/devguide/blob/master/devguide.md#requesting-access

   Example MR (requesting dev_cluster and dev_staging access): https://gitlab.cee.redhat.com/service/app-interface/merge_requests/608/diffs#diff-content-e1e2398297f1033c8844202f9135ea408b397d08
3. Repo would likely be forked. 
4. Before trying to put a Merge Request, make sure to add `@devtools-bot` with role as **Maintainer** in your forked repo settings.    
5. With your new `kerbroseid.yml` file, Put a Merge Request in Base Repo while ensuring that all automated tests are passed.
6. Once Merged, You will likely to receive email from **App SRE team automation**, specifying to your AWS credentials.
7. In Addition you should also receive invitation email from `@app-sre-bot` to join `@rhdt-dev` and `@app-sre` organisation.
(Based on permissions requested). Make sure to accept this invite. This will authorise you in dev_cluster signin.

**Please Note**: Your `dev_cluster` resource usage can be seen in AWS console.  



## Configure fabric8-analytics services

The deploy.sh script expects to find configuration in `env.sh` file.
The easiest way how to create the configuration file is to copy [env-template.sh](env-template.sh) and modify it.

```shell
$ cp env-template.sh env.sh
$ vim env.sh
```

## Deploy fabric8-analytics services

Just run the deploy script and enjoy!

```shell
$ ./deploy.sh
```

If you have already run the script previously and therefore there exists a $OC_PROJECT project,
the script purges it to start from scratch. If you want to also purge previously allocated AWS resources
(RDS db, SQS queues, S3 buckets, DynamoDB tables) use

```shell
$ ./deploy.sh --purge-aws-resources
```

Once you know that you no longer need the fabric8-analytics deployment, you can run

```shell
$ ./cleanup.sh
```

to remove the OpenShift project and all allocated AWS resources.

###### SIGNING IN: 
https://devtools-dev.ext.devshift.net:8443/console/catalog with your Github Account

In dev_console overview, Please make sure all your services are up and running with at least 1 POD instance.


### FAQ's:
1. In dev_console, `bayesian-data-importer` service is down.

**cause**: In this case you have some data messed up in your Dynamo DB Tables.
**resolution**: Completely remove **your tables only** from AWS Dynamo DB, i.e  tables prefixed with name `your_kerboros_*`. 
Redeploy `bayesian-gremlin-http` to recreate tables and then redeploy bayesian-data-importer.



## Test not-yet-merged changes

### Build in CI

Assume you have opened a PR in one of the [fabric8-analytics repositories](https://github.com/fabric8-analytics/).
Once tests are green, [CentosCI](https://ci.centos.org/) will build your image and comment on the PR:

`Your image is available in the registry: docker pull registry.devshift.net/fabric8-analytics/worker-scaler:SNAPSHOT-PR-25`

To update your dev deployment to use the above mentioned image you can use one the following ways:

- [oc edit](https://docs.openshift.com/container-platform/3.4/cli_reference/basic_cli_operations.html#edit) from command line
- editor in web interface: `Applications` -> `Deployments` -> select deployment -> `Actions` -> `Edit YAML`
- edit [deploy.sh](deploy.sh), add `"-p IMAGE_TAG=SNAPSHOT-PR-25"` (with correct tag) to corresponding `oc_process_apply` call at the end of the file and (re-)run `./deploy.sh`.

### Build in OpenShift

Update configure_os_builds.sh remotes value should contain your github accout name.
Local variable templates define all the repositories that will be cloned and build using [openshift docker build](https://docs.openshift.org/latest/dev_guide/builds/build_inputs.html#dockerfile-source).


#### Update deployments to use imagestreams

After sucessfull build of all required images user needs to update all deployments to use newly build [streams](https://docs.openshift.org/latest/architecture/core_concepts/builds_and_image_streams.html#image-streams)


# E2E test

## Configure OSIO token

If you want to run E2E tests, you will need to configure `RECOMMENDER_API_TOKEN` variable in your `env.sh` file.
You can get the token on your [openshift.io](http://openshift.io) profile page after clicking on the "Update Profile" button.

## Run E2E tests against your deployment

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

# Dockerized deployment scripts

There's also [Dockerfile](Dockerfile) and [Makefile](Makefile) to run these scripts in docker container to avoid installing the required tools.
Just prepare your `env.sh` and run

- `make deploy` to (re-)deploy to Openshift
- `make clean-deploy` to purge fabric8-analytics project from Openshift along with allocated AWS resources and (re-)deploy
- `make clean` to remove fabric8-analytics project from Openshift along with allocated AWS resources
