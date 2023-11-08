# AWS API Gateway Deployment History with Terraform

## Clone repository

```shell
git clone https://github.com/nicolai-budico/apigw-deployment-history.git
```

## Configure project
### Terraform init

Run `terraform init` for general project 
```shell
$ cd ./apigw-deployment-history
$ terraform init \
    -backend-config="bucket=<GENERAL PROJECT: STATE BUCKET NAME>" \
    -backend-config="key=<GENERAL PROJECT: STATE OBJECT KEY>" \
    -backend-config="region=<GENERAL PROJECT: STATE REGION>"
```

Run `terraform init` for cutover project 
```shell
$ cd ./apigw-deployment-history/cutover
$ terraform init \
    -backend-config="bucket=<CUTOVER PROJECT: STATE BUCKET NAME>" \
    -backend-config="key=<CUTOVER PROJECT: STATE OBJECT KEY>" \
    -backend-config="region=<CUTOVER PROJECT: STATE REGION>"
```

**Note**: If both backends are configured in the same bucket and region, then `<CUTOVER PROJECT: STATE OBJECT KEY>` for `cutover` project should differ from `<GENERAL PROJECT: STATE OBJECT KEY>` for general project

### Setup variables

#### General project
Default values are provided for all variables in general project:
```properties
# Target AWS Region
aws_region       = us-east-1
# REST API name
api_name         = the-api
# Test stage name
test_stage_name  = test
# Production stage name
prod_stage_name  = live
# Lambda function name
lambda_name      = the-lambda
# Lambda function runtime (only python3.<8-10> are supported)
lambda_runtime   = python3.10
```

To provide different values, `./apigw-deployment-history/.auto.tfvars` file may be used.

#### Cutover project
Cutover project requires the state file location of the general project to configure `terraform_remote_state` datasource.<br/>
These values are required to be provided <br/>

***File** ./apigw-deployment-history/cutover/.auto.tfvars*:
```properties
remote_backend_bucket="<GENERAL PROJECT: STATE BUCKET NAME>"
remote_backend_key="<GENERAL PROJECT: STATE OBJECT KEY>"
remote_backend_region="<GENERAL PROJECT: STATE REGION>"
```

## Configure project (automated)

The script `./configure` may help with configuring the project. It prompts necessary varible values and put into appropriate places.

```shell
$ ./configure
===============================================================================================================
   General backend configuration
---------------------------------------------------------------------------------------------------------------
Bucket: <THE BUCKET> ⏎
Key [api-deployment-history/general.tfstate]: ⏎
Region [us-east-1]: ⏎

===============================================================================================================
    Cutover backend configuration
---------------------------------------------------------------------------------------------------------------
Bucket [<THE BUCKET>]: ⏎
Key [api-deployment-history/cutover.tfstate]: ⏎
Region [us-east-1]: ⏎

===============================================================================================================
    Variables configuration
---------------------------------------------------------------------------------------------------------------
Target AWS Region [us-east-1]: ⏎
API name [the-api]: ⏎
Test stage name [test]: ⏎
Prod stage name [live]: ⏎
Lambda function name [the-lambda]: ⏎
Lambda runtime [python3.10]: ⏎

===============================================================================================================
    Terraform init: general
---------------------------------------------------------------------------------------------------------------
+ terraform init -backend-config=bucket=<THE BUCKET> -backend-config=key=api-deployment-history/general.tfstate -backend-config=region=us-east-1
...
Terraform has been successfully initialized!

===============================================================================================================
    Terraform init: cutover
---------------------------------------------------------------------------------------------------------------
+ cd cutover
+ terraform init -backend-config=bucket=<THE BUCKET> -backend-config=key=api-deployment-history/cutover.tfstate -backend-config=region=us-east-1
...
Terraform has been successfully initialized!
```

## Deploy infrastructure (general project)

```shell
$ cd ./apigw-deployment-history
$ terraform plan --refresh=true --out=general.tfplan
$ terraform apply general.tfplan
``` 

## Perform cutover (cutover project)

```shell
$ cd ./apigw-deployment-history/cutover
$ terraform plan --refresh=true --out=cutover.tfplan
$ terraform apply cutover.tfplan
``` 
