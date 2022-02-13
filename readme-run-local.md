# SWE execution in local environment

This documentation demonstrates the steps to test the developed IBM SWE gitops module locally by pointing to desired OpenShift cluster and GitHub repository.

## 1. Update terraform.tfvars

Update the below properties in `/test/stages/terraform.tfvars` file .

### 1.1 ibmcloud_api_key

Generate the key from  https://cloud.ibm.com/iam/apikeys

## 1.2 cp_entitlement_key

Get the entitlement key from  https://myibm.ibm.com/products-services/containerlibrary

## 1.3 server_url

The server where you are going to apply the terraform module.

The `oc login` command of the OCP cluster would be like this.

```
oc login --token=sha256~62DwshrR-4tR2w_..............i8dx8 --server=https://c117-e.us-south.containers.cloud.ibm.com:11111
```
Here the `server_url` is `https://c117-e.us-south.containers.cloud.ibm.com:11111`

## 1.4 login_token

From the above exmaple, the `login_token` is `sha256~62DwshrR-4tR2w_..............i8dx8`

## 1.5 namespace

The namespace could be `cp4waiops` where this module is going to run.

## 1.6 git_org

Create new org in github and give the value. 

Click the `New Organization` button in https://github.com/settings/organizations  to create new Org.

## 1.7 git_username

You github user name

## 1.8 git_token

You github Personal access token.

Click the `Generate New Token` button in https://github.com/settings/tokens to create token

## 1.9 git_repo

Give any non existing github repo name. This will be created while running this module.

