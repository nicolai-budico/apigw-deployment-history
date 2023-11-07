#!/bin/sh

set -e

aws lambda add-permission \
  --statement-id "${STATEMENT_ID}" \
  --principal "${PRINCIPAL}" \
  --source-arn "${SOURCE_ARN}" \
  --action "${ACTION}" \
  --function-name "${FUNCTION_NAME}" \
  --qualifier "${QUALIFIER}" \
  1>&2
