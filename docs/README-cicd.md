# fabric8-analytics CI/CD

fabric8-analytics project relies on [CentOS CI](https://ci.centos.org/) for its CI/CD needs.
The process of configuring CI/CD for a new repository is, unfortunately, quite cumbersome
(the team doesn't own the whole pipeline and some approvals are required).

Let's get into it.

## Configure CI/CD for a new repository

### Requirements

You should have following files in your repository before proceeding forward:

* have `Dockerfile` in your repository
    * CentOS 7 based Dockerfile
* have `Dockerfile.rhel` in your repository
    * same as Dockerfile, but base image should be RHEL
    * optional at the beginning; it can be added later, when everything works
* have `runtest.sh` script in your repository
    * script to run unit tests, it will be executed in CI
* have OpenShift template in `openshift/template.yaml`

Additional requirements:
* your repository lives in [fabric8-analytics organization](https://github.com/fabric8-analytics/) on GitHub


### Step 1: Create a repository in quay.io Docker registry
 
If you want to build Docker images and push them to quay.io registry (we push to quay.io, not to dockerhub),
then you will need to whitelist the name of your Docker repository there.
    
Simply go to <internal GitLab URL>/housekeeping and follow instructions on how to whitelist your new repository.
If you don't know the GitLab URL, ask you peers ;)
    
You will likely want to whitelist two repositories:
* `openshiftio/your-service-name`
    * CentOS-based image
* `openshiftio/rhel-your-service-name`
    * RHEL-based image

Note even if you don't plan to provide RHEL-based image immediately,
asking for the repository to be whitelisted will not hurt anything.

### Step 2: Create Jenkins jobs in CentOS CI

The next step is to create Jenkins jobs in CentOS CI.

To do that, fork and clone [openshiftio-cico-jobs](https://github.com/openshiftio/openshiftio-cico-jobs)
repository.

Then edit [`devtools-ci-index.yaml`](https://github.com/openshiftio/openshiftio-cico-jobs/blob/master/devtools-ci-index.yaml)
configuration file.    
If you're wondering what the heck is that file, check out [Jenkins Job Builder documentation](https://docs.openstack.org/infra/jenkins-job-builder/definition.html).

#### Configure master branch build with deployment and E2E tests

Add following lines (remove comments) if you want Jenkins to automatically deploy your service to staging environment,
run E2E tests against it and automatically rollback to previous version if E2E tests failed.

```bash
- '{ci_project}-{git_repo}-f8a-build-master':     # template reference, keep intact
    git_organization: fabric8-analytics           # GitHub organization where your project lives
    git_repo: fabric8-analytics-new-service       # short name of your GitHub repository
    ci_project: 'devtools'                        # job group in Jenkins, keep intact
    ci_cmd: '/bin/bash cico_build_deploy.sh'      # script to run on merge to master
    saas_git: saas-analytics                      # short name of the GitHub repository for tracking deployments; always [saas-analytics](https://github.com/openshiftio/saas-analytics)
    deployment_units: 'your-service-name'         # saas service names, separated by spaces; can be the same as deployment_configs, for simplicity
    deployment_configs: 'your-service-name'       # name of the OpenShift deployment config, e.g.: https://github.com/fabric8-analytics/fabric8-analytics-data-model/blob/f058982e7b75dccf97b5adec9ea975530a1731fe/openshift/template.yaml#L29
    timeout: '30m'                                # how long to wait before giving up (reaching the time limit will fail the build)
    extra_target: rhel                            # keep if you plan to build also RHEL-based images, remove the line otherwise
```

#### Configure master branch build with deployment, without E2E tests

Alternatively, if you only want to deploy resulting image to staging environment,
without running E2E tests after deployment, you can use following snippet:

```bash
- '{ci_project}-{git_repo}-build-master':         # template reference, keep intact
    git_organization: fabric8-analytics           # GitHub organization where your project lives
    git_repo: fabric8-analytics-new-service       # short name of your GitHub repository
    saas_git: saas-analytics                      # short name of the GitHub repository for tracking deployments; always [saas-analytics](https://github.com/openshiftio/saas-analytics)
    prj_name: bayesian-preview                    # OpenShift namespace, keep intact
    saas_service_name: your-service-name          # saas service name
    ci_project: 'devtools'                        # job group in Jenkins, keep intact
    ci_cmd: '/bin/bash cico_build_deploy.sh'      # script to run on merge to master
    timeout: '30m'                                # how long to wait before giving up (reaching the time limit will fail the build)
    extra_target: rhel                            # keep if you plan to build also RHEL-based images, remove the line otherwise
```

This is useful for example when you're building and deploying OpenShift cronjobs. Cronjobs will run according to schedule.

#### Configure pull request builds

If you'd like to also enable CI for pull requests in your repository, add following lines:

```bash
- '{ci_project}-{git_repo}-fabric8-analytics':    # template reference, keep intact
    git_organization: fabric8-analytics           # GitHub organization where your project lives
    git_repo: fabric8-analytics-new-service       # short name of your GitHub repository
    ci_project: 'devtools'                        # job group in Jenkins, keep intact
    ci_cmd: '/bin/bash cico_run_tests.sh'         # script to run on pull requests
    timeout: '30m'                                # how long to wait before giving up (reaching the time limit will fail the build)
    registry: 'quay.io'                           # registry where to find Docker images for your service
    image_name: 'openshiftio/your-service-name'   # image name
```

#### Enable QA checks in CI

The last piece of configuration that you want to add to the `devtools-ci-index.yaml` file is to enable quality assurance checks on your repository:
```bash
- '{ci_project}-{git_repo}-fabric8-analytics-pylint':
    git_repo: fabric8-analytics-new-service
- '{ci_project}-{git_repo}-fabric8-analytics-pydoc':
    git_repo: fabric8-analytics-new-service
```

Once you're done editing the configuration file, open a pull request with your changes.


### Step 4: Add CI/CD and QA scripts to your new repository

Copy CI/CD and QA scripts from [docs/cicd](docs/cicd/) to the root of your repository:

```bash
cp -r docs/cicd/* ~/path/to/your/repository/
```

Now you need to tweak the scripts for your needs.

Then fix Makefile by providing the correct repository name for your Docker images:

```bash
cd ~/path/to/your/repository/
sed -i 's|REPOSITORY_NAME|openshiftio/your-service-name|g' Makefile
```

Open `cico_setup.sh` and check `prep()` function definition. This function is called in CI and its purpose
is to prepare the machine in CI on which your tests will be running. 
If you need any RPM packages or services to be installed on the machine,
this is the place where to do it. Note CI machines have CentOS 7 installed on them.

Then check `cico_build_deploy.sh` and `cico_run_tests.sh` scripts.
Those scripts will be executed in CI. The first on every merge to master
branch and the second on every pull request.

The last step is to update QA scripts. Following scripts require you to explicitly
specify which directories in your repository should be checked by them:

* `check-docstyle.sh`
* `detect-common-errors.sh`
* `detect-dead-code.sh`
* `run-linter.sh`

Edit the files and specify a list of directories to check, for example:

```bash
directories="src tests"
```

### Step 5: Add deployment configuration file to the saas-analytics repository

A tool called [saasherder](https://github.com/openshiftio/saasherder) is responsible for all deployments
to staging and production.

fabric8-analytics projects need to provide deployment configuration details as a config file stored
in [openshiftio/saas-analytics](https://github.com/openshiftio/saas-analytics) repository.

The configuration may look like this:

```yaml
services:
- hash: none
  hash_length: 7
  name: your-service-name  # same as "saas_service_name" and "deployment_units" in devtools-ci-index.yaml
  environments:
  - name: production       # configuration for production deployment
    parameters:            # params for OpenShift template, they will be different for your service
      ENABLE_SCHEDULING: 1
      DOCKER_REGISTRY: quay.io
      DOCKER_IMAGE: openshiftio/rhel-fabric8-analytics-release-monitor
      REPLICAS: 1
      NPM_URL: https://registry.npmjs.org/
      PYPI_URL: https://pypi.org/
      SLEEP_INTERVAL: 5
  - name: staging          # configuration for staging deployment
    parameters:
      ENABLE_SCHEDULING: 0
      DOCKER_REGISTRY: quay.io
      DOCKER_IMAGE: openshiftio/fabric8-analytics-release-monitor
      REPLICAS: 1
      NPM_URL: https://registry.npmjs.org/
      PYPI_URL: https://pypi.org/
      SLEEP_INTERVAL: 30
  path: /openshift/template.yaml
url: https://github.com/fabric8-analytics/fabric8-analytics-release-monitor
```

Note `hash: none` has a special meaning. If the value is `none`,
it means that your service won't be deployed to production. Only to staging environment.

Create a config file for your service and open a pull request
in [openshiftio/saas-analytics](https://github.com/openshiftio/saas-analytics) repository.


### Step 6: Configure webhooks in your GitHub repository

Can't believe you made it this far :) Don't worry, you're almost there!

The last step is to configure webhooks in your GitHub repository.
Please refer to the official [CentOS CI documentation](https://wiki.centos.org/QaWiki/CI/GithubIntegration) for more information.

Only `Mode 1: Trigger on Every Commit` and `Mode 2: Trigger a build for each Pull Request` sections are relevant.

Congratulations! You should be ready to deploy your service to staging environment for the first time.

Simply push something to your master branch and watch CI to do the magic.


## Promote to production

If your service works in staging as expected, you may promote it to production.

Simply edit [saas-analytics config YAML](https://github.com/openshiftio/saas-analytics) that belongs to your service
and update `hash` key. The value should be a commit hash that was previously build and tested in CI.

Example:
```yaml
services:
- hash: d21bab577722507385acf37f3242c2a8572f1abe
  ...
```

The way it works is that you're basically describing a desired deployment state in which production should be.
I.e. if you need to downgrade to a previous version, simply change the hash again.

Open a pull request with your changes and once it gets merged, [`devtools-saas-analytics-promote-to-prod`](https://ci.centos.org/view/Devtools/job/devtools-saas-analytics-promote-to-prod/)
job in CI will update production environment.
The promote-to-prod job is maintained by Service Delivery team.
