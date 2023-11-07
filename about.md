# AWS API Gateway Deployment History with Terraform

AWS API Gateway deployment is a critical component for managing and versioning APIs. Many organizations use Terraform to automate the deployment process, ensuring consistent and repeatable infrastructure provisioning. However, when it comes to managing API Gateway deployments with Terraform, there are some challenges, particularly in retaining deployment history. In this article, we will explore the intricacies of AWS API Gateway deployments and how to maintain a deployment history while using Terraform.

## Goals

The primary goals when managing AWS API Gateway deployments with Terraform are as follows:

1. **Deployment Testing**: Ensure the ability to deploy changes to the `test` stage, test those changes, and confirm that the stage is working correctly before proceeding with the cutover to the current `production` stage.

2. **Rollback Capability**: Maintain the capability to rollback to a previous deployment in case any issues or unexpected problems arise with the current deployment.

To achieve these goals, it is essential to address the limitations and challenges associated with Terraform's management of API Gateway deployments.

## Approach

1. Apply API Gateway changes
1. Create deployment
1. Point `test` stage to the newly created deployment
1. Confirm `test` stage works good
1. Point `live` stage to the newly created deployment to switch production traffic the new version

## Canary deployment

AWS API Gateway has canary deployment which allow to confirm changes are good and then switch to the new version.\
The inconvenience with this canary deployments is that canary deployment routes traffic on probability manner and there are no guarantee that all "tests" are executed against testing stage on one side and part of the production traffic from real clients will be routed to the testing stage on the other side. Second, this solution doesn't keep deployment history and there is no way to rollback to the previous version after cutover.

## Lambda integration

AWS Lambda functions are often integrated with API Gateway to handle requests. And here is a point that should be considered when AWS Lambda integration is used.\
When Lambda function is changed and new deployment is created, old deployments have integrations pointing to the same Lambda function. If Lambda function is changed for all deployments, the profit from deployment history will be lost. To achieve this, each API method should have integration pointing to the specific Lambda function version.

## `aws_api_gateway_deployment` resource

AWS API Gateway deployments in Terraform are primarily managed through the `aws_api_gateway_deployment` resource. This resource allows you to create, update, and delete deployments. However, it lacks a built-in mechanism to maintain a history of deployments. When a new deployment is created, the previous deployment is not preserved but is instead replaced by the new deployment. This means that there is no native way to revert to a previous deployment if issues arise with the current one.

## `aws_lambda_permission` resource

AWS Lambda functions are often integrated with API Gateway to handle requests. When a Lambda function is updated (e.g., a new version or configuration change), Terraform manages this through the `aws_lambda_permission` resource, which authorizes API Gateway to invoke the Lambda function. However, when the Lambda function changes, Terraform recreates this resource, effectively removing permissions for the previous Lambda version, which is an integration for previous deployment version(s).

To ensure a robust deployment history and the ability to roll back to previous deployments, it's crucial to preserve the permissions for the previous Lambda versions that API Gateway can invoke. This requirement allows you to maintain consistency between API Gateway deployments and Lambda function versions. When rolling back to a previous deployment, you should still be able to access and invoke the corresponding Lambda function version without any disruptions.

## Managed resources

While Terraform completely manages resource lifecycles, retaining deployment history and keeping permissions on Lambda versions requires a different approach. It is possible to create AWS `Deployment` resources and resource-based policies for Lambda outside the Terraform state using the AWS CLI tool or API calls:

```shell
aws apigateway create-deployment --rest-api-id "${REST_API_ID}" --description "${DESCRIPTION}"
```

Lambda resource-based policy can be created using `aws lambda add-permissions` command:

```shell
aws lambda add-permission \
  --statement-id "${STATEMENT_ID}" \
  --principal "${PRINCIPAL}" \
  --source-arn "${SOURCE_ARN}" \
  --action "${ACTION}" \
  --function-name "${FUNCTION_NAME}" \
  --qualifier "${QUALIFIER}"
```

## Caution

It's important to note that for each Lambda function change, a new version is published, and a new deployment is created. Therefore, it's necessary to track obsolete deployments and Lambda versions, as they consume storage. For more information on this topic, refer to (Monitoring Lambda code storage)[https://docs.aws.amazon.com/lambda/latest/operatorguide/code-storage.html].

## Implementation

https://github.com/nicolai-budico/apigw-deployment-history

The example consists of API Gateway REST APIs with single method `GET /example` which is backed up with the Lambda function.\
There are two stages in the API - `test` and `live`. `test` stage always points to the latest deployment. `live` stage remains unchanged until requested.\

First of all the Lambda function which serves requests to `GET /example` method is declared. The `publish` flag set to `true` to force creation of new version each time Lambda function is changed:

```terraform
resource "aws_lambda_function" "lambda" {
  publish        = true
  ...
}
```

Then API Gateway REST API with `GET /example` method. The method has Lambda integration that points to the particular Lambda version.

```terraform
resource "aws_api_gateway_rest_api" "api" {
  body = jsonencode({
    paths = {
      "/example" = {
        get = {
          x-amazon-apigateway-integration = {
            type                = "aws_proxy"
            httpMethod          = "POST"
            uri                 = aws_lambda_function.lambda.qualified_invoke_arn
            passthroughBehavior = "when_no_match"
            timeoutInMillis     = 29000
          }
        }
      }
    }
  })
}
```

When Lambda function and API are created/updated we need to deploy API and create stage that points to the newly created deployment.\
To do this, `aws apigateway create-deployment` cli command is called using `shell_script` resource from `scottwinkler/shell` provider:

```terraform
resource "shell_script" "deploy_api" {
  lifecycle_commands {
    create = file("${path.module}/create-deployment.sh")
    delete = file("${path.module}/delete-deployment.sh")
  }

  triggers = var.triggers

  environment = {
    REST_API_ID = aws_api_gateway_rest_api.api.id
    DESCRIPTION = "Deployment ${timestamp()}"
  }
}
```

*${path.module}/create-deployment.sh*:
```shell
#!/bin/bash
set -e
aws apigateway create-deployment --rest-api-id  "${REST_API_ID}" --description "${DESCRIPTION}"
```

`shell_script` parses command output as a JSON object and store it in the `output` property. After applying this resource, new deployment id will be accessible by `shell_script.deploy_api.output["id"]`. Now this deployment id can be used in stage resource:

```terraform
resource "aws_api_gateway_stage" "test_stage" {
  deployment_id = shell_script.deploy_api.output["id"]
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "test"
  ...
}
```

At this point `test` stage is available to perform tests and confirm that changes are OK for production traffic:
```text
https://<api id>.execute-api.<region>.amazonaws.com/test/example
```

### Cutover

When changes are tested and confirmed that are ready for production traffic, it is time to switch production traffic to the newly created deployment.\
As of requirement to keep as mach resources as possible in Terraform, the "production" stage is described as a Terraform resource in different Terraform project in subfolder `cutover`.\
To create/update "prod" stage these values are required from previous step: REST API id, deployment id and region where infrastructure is deployed. Values can be provided as Terraform variables or with `terraform_remote_state` datasource.

```terraform
resource "aws_api_gateway_stage" "live_stage" {
  depends_on = [
    data.terraform_remote_state.infrastructure
  ]

  deployment_id = data.terraform_remote_state.infrastructure.outputs.deployment_id
  rest_api_id   = data.terraform_remote_state.infrastructure.outputs.rest_api_id
  stage_name    = "live"
}
```

In few minutes after applying infrastructure changes in `cutover` project, production traffic will be switched to the newly created deployment.
