## Open Merge Request for AWS Credentials
Next step is to get credentials to signin in your dev AWS Console
1. Make sure your Github/Gitlab account has primary email as `xyz@redhat.com`
2. Open a MR at https://gitlab.cee.redhat.com/dtsd/devguide/blob/master/devguide.md#requesting-access

   Example MR (requesting dev_cluster and dev_staging access): https://gitlab.cee.redhat.com/service/app-interface/merge_requests/608/diffs#diff-content-e1e2398297f1033c8844202f9135ea408b397d08
3. Repo would likely be forked. 
4. Before trying to put a Merge Request, make sure to add `@devtools-bot` with role as **Maintainer** in your forked repo settings.    
5. With your new `kerbroseid.yml` file, Put a Merge Request in Base Repo while ensuring that all automated tests are passed.
6. Once Merged, You should receive email from **App SRE team automation**, specifying your dev_console's AWS credentials.
7. In Addition you should also receive invitation email from `@app-sre-bot` to join `@rhdt-dev` and `@app-sre` organisation.
(Based on permissions requested). Make sure to accept this invite. This will authorise you in dev_cluster signin.

**Please Note**: Your `dev_cluster` resource usage can be seen in AWS console.  
 
 Go to [README.md](README.md)