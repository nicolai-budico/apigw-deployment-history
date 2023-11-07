#!/bin/sh

aws lambda remove-permission \
  --statement-id "${STATEMENT_ID}" \
  --function-name "${FUNCTION_NAME}" \
  --qualifier "${QUALIFIER}" \
  1>&2

set -e

aws lambda add-permission \
  --statement-id "${STATEMENT_ID}" \
  --principal "${PRINCIPAL}" \
  --source-arn "${SOURCE_ARN}" \
  --action "${ACTION}" \
  --function-name "${FUNCTION_NAME}" \
  --qualifier "${QUALIFIER}" \
  1>&2
