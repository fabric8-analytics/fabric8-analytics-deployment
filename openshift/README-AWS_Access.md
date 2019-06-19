## Open Merge Request for AWS Credentials
The next step is to get credentials to get access to your own AWS console.

1. Make sure your Github/Gitlab account has primary email as `xyz@redhat.com`

2. Create a Merge Request(MR) at https://gitlab.cee.redhat.com/dtsd/devguide/blob/master/devguide.md#requesting-access
   > Example Merge Request: [requesting dev_cluster and dev_staging access](https://gitlab.cee.redhat.com/service/app-interface/merge_requests/608/diffs#diff-content-e1e2398297f1033c8844202f9135ea408b397d08)

3. Fork [Base Repo](https://gitlab.cee.redhat.com/service/app-interface) and add `@devtools-bot` with the role as **Maintainer** in your forked repo settings.

4. With your new `kerbroseid.yml` file, Create a Merge Request in Base Repo while ensuring that all automated tests are passed.

5. Once Merged, You should receive an email from **App SRE team automation**, specifying your dev_console's AWS credentials.

6. In Addition, you should also receive an invitation email from `@app-sre-bot` to join `@rhdt-dev` and `@app-sre` organization.
(Based on permissions requested). Make sure to accept this invite. This will authorize you in dev_cluster sign in.

**Please Note**: Your `dev_cluster` resource usage can be seen in the AWS console.  
 
 Go to [README.md](README.md)